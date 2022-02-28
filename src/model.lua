local _ok, _platformPlugin = am.plugin.safe_get("platform")
if not _ok then
    log_error("Cannot determine platform!")
    return
end
local _ok, _platform = _platformPlugin.get_platform()
if not _ok then
    log_error("Cannot determine platform!")
    return
end

local _downloadLinks = hjson.parse(fs.read_file("__xtz/sources.hjson"))

local _downlaodUrls = nil

if _platform.OS == "unix" then
	_downlaodUrls = _downloadLinks["linux-x86_x64"]
    if _platform.SYSTEM_TYPE:match("[Aa]arch64") then
        _downlaodUrls = _downloadLinks["linux-arm64"]
    else
        local _ok, _cpuinfo = fs.safe_read_file("/proc/cpuinfo")
        if _ok and not _cpuinfo:match(" adx ") then
            _downlaodUrls = _downloadLinks["linux-x86_x64-no-adx"]
        end
    end
end

if _downlaodUrls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model({
		DOWNLOAD_URLS = _downlaodUrls, 
		WANTED_BINARIES = {
			"node", "client", "accuser", "baker", "endorser", "accuser-next", "baker-next", "endorser-next"
		},
        AVAILABLE = {
            endorser = type(_downlaodUrls["endorser"]) == "string"
        },
		AVAILABLE_NEXT = {
			accuser = type(_downlaodUrls["accuser-next"]) == "string",
			baker = type(_downlaodUrls["baker-next"]) == "string",
			endorser = type(_downlaodUrls["endorser-next"]) == "string"
		}
	}, 
	{merge = true, overwrite = true}
)


am.app.set_model(
    {
        RPC_ADDR = am.app.get_configuration("RPC_ADDR", "127.0.0.1"),
        REMOTE_SIGNER_ADDR = am.app.get_configuration("REMOTE_SIGNER_ADDR", "http://127.0.0.1:2222/"),
		SERVICE_CONFIGURATION = util.merge_tables(
            {
                TimeoutStopSec = 300,
            },
            type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and am.app.get_configuration("SERVICE_CONFIGURATION") or {},
            true
        )
    },
    { merge = true, overwrite = true }
)
