local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local ok, error = fs.safe_mkdirp("data")
ami_assert(ok, "failed to create data directory: ".. tostring(error))
local ok, uid = fs.safe_getuid(user)
ami_assert(ok, "Failed to get " .. user .. "uid - " .. (uid or ""))

log_info("Configuring " .. am.app.get("id") .. " services...")

local backend = am.app.get_configuration("backend", os.getenv("ASCEND_SERVICES") ~= nil and "ascend" or "systemd")

local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"
services.remove_all_services() -- cleanup past install

for k, v in pairs(services.all) do
	local service_id = k
	local source_file = string.interpolate("${file}.${extension}", {
		file = v,
		extension = backend == "ascend" and "ascend.hjson" or "service"
	})
	local ok, err = service_manager.safe_install_service(source_file, service_id)
	ami_assert(ok, "Failed to install " .. service_id .. ".service " .. (err or ""))
end

log_success(am.app.get("id") .. " services configured")

local config_file = am.app.get_configuration("CONFIG_FILE")
if type(config_file) == "table" and not table.is_array(config_file) then
	log_info("Creating config file...")
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.write_file("./data/.tezos-node/config.json", hjson.stringify_to_json(config_file))
elseif fs.exists("./__xtz/node-config.json") then
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.copy_file("./__xtz/node-config.json", "./data/.tezos-node/config.json")
end

-- vote file
local vote_file = am.app.get_configuration("VOTE_FILE")
local vote_file_result = {}
local ok, baseline_raw = fs.safe_read_file("./__xtz/assets/default-vote-file.json")
if ok then
	local ok, baseline = hjson.safe_parse(baseline_raw)
	if ok and type(baseline) == "table" and not table.is_array(baseline) then
		vote_file_result = baseline
	end
end
if type(vote_file) == "table" and not table.is_array(vote_file) then
	vote_file_result = util.merge_tables(vote_file_result, vote_file, true)
elseif vote_file then
	log_warn("Invalid 'VOTE_FILE' detected!")
end
fs.write_file("./data/vote-file.json", hjson.stringify_to_json(vote_file_result))

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then
	require"__xtz.prism.setup"
end

-- finalize
local ok, error = fs.chown(os.cwd(), uid, uid, {recurse = true})
ami_assert(ok, "Failed to chown data - " .. (error or ""))