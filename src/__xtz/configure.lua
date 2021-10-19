local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local _ok, _error = fs.safe_mkdirp("data")
local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))

log_info("Configuring " .. am.app.get("id") .. " services...")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin - " .. tostring(_systemctl))

local _nodeServiceId = am.app.get("id") .. "-xtz-node"
local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/node.service"), _nodeServiceId)
ami_assert(_ok, "Failed to install " .. _nodeServiceId .. ".service " .. (_error or ""))

if am.app.get_configuration("NODE_TYPE", "rpc") == "baker" then
	local _bakerServiceId = am.app.get("id") .. "-xtz-baker"
	local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/baker.service"), _bakerServiceId)
	ami_assert(_ok, "Failed to install " .. _bakerServiceId .. ".service " .. (_error or ""))

	local _endorserServiceId = am.app.get("id") .. "-xtz-endorser"
	local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/endorser.service"), _endorserServiceId)
	ami_assert(_ok, "Failed to install " .. _endorserServiceId .. ".service " .. (_error or ""))

	local _accuserServiceId = am.app.get("id") .. "-xtz-accuser"
	local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/accuser.service"), _accuserServiceId)
	ami_assert(_ok, "Failed to install " .. _accuserServiceId .. ".service " .. (_error or ""))

	local _urls = am.app.get_model("DOWNLOAD_URLS")
	ami_assert(type(_urls) == "table", "Invalid download URLs!")

	if am.app.get_model({ "AVAILABLE_NEXT", "baker" }, false) then
		local _bakerNextServiceId = am.app.get("id") .. "-xtz-baker-next"
		local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/baker-next.service"), _bakerNextServiceId)
		ami_assert(_ok, "Failed to install " .. _bakerNextServiceId .. ".service " .. (_error or ""))
	end

	if am.app.get_model({ "AVAILABLE_NEXT", "endorser" }, false) then
		local _endorserNextServiceId = am.app.get("id") .. "-xtz-endorser-next"
		local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/endorser-next.service"), _endorserNextServiceId)
		ami_assert(_ok, "Failed to install " .. _endorserNextServiceId .. ".service " .. (_error or ""))
	end

	if am.app.get_model({ "AVAILABLE_NEXT", "accuser" }, false) then
		local _accuserNextServiceId = am.app.get("id") .. "-xtz-accuser-next"
		local _ok, _error = _systemctl.safe_install_service(am.app.get_model("SERVICE_FILE", "__xtz/assets/accuser-next.service"), _accuserNextServiceId)
		ami_assert(_ok, "Failed to install " .. _accuserNextServiceId .. ".service " .. (_error or ""))
	end
end

log_success(am.app.get("id") .. " services configured")

log_info("Downloadgin zcash parameters...")

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
	fs.write_file("./data/.tezos-node/config.json", hjson.stringify_to_json(_configFile))
end

local _ok, _error = fs.chown("data", _uid, _uid, {recure = true})
ami_assert(_ok, "Failed to chown data - " .. (_error or ""))