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
    end
end

if _downlaodUrls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model(
    {
        DOWNLOAD_URLS = am.app.get_configuration("SOURCES", _downlaodUrls),
    },
    { merge = true, overwrite = true }
)

local _services = require("__xtz.services")
local _wantedBinaries = _services.allBinaries

---@type string[]
local _configuredAdditionalKeys = am.app.get_configuration("additional_keys_aliases", {})
if not util.is_array(_configuredAdditionalKeys) then
    _configuredAdditionalKeys = {}
    log_warn("invalid additional_keys configuration (skipped)")
end
---@type string[]
local _configuredKeys = am.app.get_configuration("keys_aliases", { "baker" })
local _keys = "baker"
if util.is_array(_configuredKeys) then
    _keys = string.join(" ", table.unpack(util.merge_arrays(_configuredKeys, _configuredAdditionalKeys)))
else
    log_warn("invalid keys configuration (skipped)")
end

am.app.set_model(
    {
        WANTED_BINARIES = _wantedBinaries,
        RPC_ADDR = am.app.get_configuration("RPC_ADDR", "127.0.0.1"),
        REMOTE_SIGNER_ADDR = am.app.get_configuration("REMOTE_SIGNER_ADDR", "http://127.0.0.1:20090/"),
		SERVICE_CONFIGURATION = util.merge_tables(
            {
                TimeoutStopSec = 300,
            },
            type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and am.app.get_configuration("SERVICE_CONFIGURATION") or {},
            true
        ),
        TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info"),
        KEYS_ALIASES = _keys
    },
    { merge = true, overwrite = true }
)
