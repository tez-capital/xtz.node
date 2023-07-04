local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _ok, _error = fs.safe_mkdirp("data")
local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

log_info("Configuring " .. am.app.get("id") .. " services...")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin - " .. tostring(_systemctl))

local _services = require"__xtz.services"
_services.remove_all_services() -- cleanup past install

for k, v in pairs(_services.all) do
	local _serviceId = k
	local _ok, _error = _systemctl.safe_install_service(v, _serviceId)
	ami_assert(_ok, "Failed to install " .. _serviceId .. ".service " .. (_error or ""))
end

log_success(am.app.get("id") .. " services configured")

log_info("Downloading zcash parameters... (This may take few minutes.)")

local _download_zk_params = require"__xtz.download-zk-params"
local _ok, _error = _download_zk_params()
ami_assert(_ok, "Failed to fetch params: " .. tostring(_error))

local _configFile = am.app.get_configuration("CONFIG_FILE")
if type(_configFile) == "table" and not table.is_array(_configFile) then
	log_info("Creating config file...")
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.write_file("./data/.tezos-node/config.json", hjson.stringify_to_json(_configFile))
elseif fs.exists("./__xtz/node-config.json") then
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.copy_file("./__xtz/node-config.json", "./data/.tezos-node/config.json")
end

-- vote file
local _voteFile = am.app.get_configuration("VOTE_FILE")
local _voteFileResult = {}
local _ok, _baselineFile = fs.safe_read_file("./__xtz/assets/default-vote-file.json")
if _ok then
	local _ok, _baseline = hjson.safe_parse(_baselineFile)
	if _ok and type(_baseline) == "table" and not table.is_array(_baseline) then
		_voteFileResult = _baseline
	end
end
if type(_voteFile) == "table" and not table.is_array(_voteFile) then
	_voteFileResult = util.merge_tables(_voteFileResult, _voteFile, true)
elseif _voteFile then
	log_warn("Invalid 'VOTE_FILE' detected!")
end
fs.write_file("./data/vote-file.json", hjson.stringify_to_json(_voteFileResult))

-- finalize
local _ok, _error = fs.chown(os.cwd(), _uid, _uid, {recurse = true})
ami_assert(_ok, "Failed to chown data - " .. (_error or ""))