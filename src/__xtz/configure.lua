local user = am.app.get("user")
ami_assert(type(user) == "string", "user not specified...", EXIT_INVALID_CONFIGURATION)
local uid, err = fs.getuid(user)
ami_assert(uid, "failed to get " .. user .. "uid - " .. tostring(err))

local ok, error = fs.mkdirp("data")
ami_assert(ok, "failed to create data directory: " .. tostring(error))

log_info("configuring " .. am.app.get("id") .. " services...")
local service_manager = require "__xtz.service-manager"
local services = require "__xtz.services"

service_manager.remove_services(services.cleanup_names)
service_manager.install_services(services.active)
log_success(am.app.get("id") .. " services configured")

local config_file = am.app.get_configuration("CONFIG_FILE")
if type(config_file) == "table" and not table.is_array(config_file) then
	log_info("Creating config file...")
	fs.mkdirp("./data/.tezos-node/")
	fs.write_file("./data/.tezos-node/config.json", hjson.stringify_to_json(config_file))
elseif fs.exists("./__xtz/node-config.json") then
	fs.mkdirp("./data/.tezos-node/")
	fs.copy_file("./__xtz/node-config.json", "./data/.tezos-node/config.json")
end

-- vote file
local vote_file = am.app.get_configuration("VOTE_FILE")
local vote_file_result = {}
local baseline_raw, err = fs.read_file("./__xtz/assets/default-vote-file.json")
if baseline_raw then
	local baseline, err = hjson.parse(baseline_raw)
	if ok and type(baseline) == "table" and not table.is_array(baseline) then
		vote_file_result = baseline
	end
end
if type(vote_file) == "table" and not table.is_array(vote_file) then
	vote_file_result = util.merge_tables(vote_file_result, vote_file, true)
elseif vote_file then
	log_warn("invalid 'VOTE_FILE' detected!")
end
fs.write_file("./data/vote-file.json", hjson.stringify_to_json(vote_file_result))

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then require "__xtz.prism.setup" end

-- check for deprecated files
if fs.exists("additional_key_aliases.list") then
	log_warn(
		"'additional_key_aliases.list' is deprecated. Please use '... modify --add configuration.key_aliases <key alias>' instead to edit keys in app.json."
	)
end

-- finalize
require "__xtz.base_utils".setup_file_ownership()
