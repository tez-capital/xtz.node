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

for k, v in pairs(_services.node) do
	local _serviceId = k
	local _ok, _error = _systemctl.safe_install_service(v, _serviceId)
	ami_assert(_ok, "Failed to install " .. _serviceId .. ".service " .. (_error or ""))
end

if am.app.get_configuration("NODE_TYPE", "rpc") == "baker" then
	for k, v in pairs(_services.baker) do
		local _serviceId = k
		local _ok, _error = _systemctl.safe_install_service(v, _serviceId)
		ami_assert(_ok, "Failed to install " .. _serviceId .. ".service " .. (_error or ""))
	end
end

log_success(am.app.get("id") .. " services configured")

log_info("Downloading zcash parameters...")

local _fetchScriptPath = "bin/fetch-params.sh"
local _ok, _error = net.safe_download_file("https://raw.githubusercontent.com/zcash/zcash/master/zcutil/fetch-params.sh", _fetchScriptPath, {followRedirects = true})
if not _ok then 
    log_error("Failed to download fetch-params.sh - " .. (_error or '-').. "!")
    return
end

if fs.exists(_fetchScriptPath) then -- we download only on debian
    log_info("Downloading params... (This may take few minutes.)")
    local _proc = proc.spawn("/bin/bash", { _fetchScriptPath }, {
        stdio = { stderr = "pipe" },
        wait = true,
        env = { HOME = path.combine(os.cwd(), "data") }
    })
    ami_assert(_proc.exitcode == 0, "Failed to fetch params: " .. _proc.stderrStream:read("a"))
    log_success("Sprout parameters downloaded...")
end

local _configFile = am.app.get_configuration("CONFIG_FILE")
if type(_configFile) == "table" and not table.is_array(_configFile) then
	log_info("Creating config file...")
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.write_file("./data/.tezos-node/config.json", hjson.stringify_to_json(_configFile))
elseif fs.exists("./__xtz/node-config.json") then
	fs.safe_mkdirp("./data/.tezos-node/")
	fs.copy_file("./__xtz/node-config.json", "./data/.tezos-node/config.json")
end

local _ok, _error = fs.chown(os.cwd(), _uid, _uid, {recurse = true})
ami_assert(_ok, "Failed to chown data - " .. (_error or ""))