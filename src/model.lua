local ok, platform_plugin = am.plugin.safe_get("platform")
if not ok then
    log_error("Cannot determine platform!")
    return
end
local ok, platform = platform_plugin.get_platform()
if not ok then
    log_error("Cannot determine platform!")
    return
end

local download_links = hjson.parse(fs.read_file("__xtz/sources.hjson"))

local download_urls = nil

if platform.OS == "unix" then
	download_urls = download_links["linux-x86_64"]
    if platform.SYSTEM_TYPE:match("[Aa]arch64") then
        download_urls = download_links["linux-arm64"]
    end
end

if download_urls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model(
    {
        DOWNLOAD_URLS = am.app.get_configuration("SOURCES", download_urls),
    },
    { merge = true, overwrite = true }
)

local services = require("__xtz.services")
local wanted_binaries = services.all_binaries

---@type string[]
local configured_additional_keys = am.app.get_configuration("additional_key_aliases", {})
if not util.is_array(configured_additional_keys) then
    configured_additional_keys = {}
    log_warn("invalid additional_key_aliases configuration (skipped)")
end
---@type string[]
local configured_keys = am.app.get_configuration("key_aliases", { "baker" })
local keys = "baker"
if util.is_array(configured_additional_keys) then
    keys = string.join(" ", table.unpack(util.merge_arrays(configured_keys, configured_additional_keys)))
else
    log_warn("invalid keys configuration (skipped)")
end
local TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info")

--// TODO: DAL
local BAKER_STARTUP_ARGS = am.app.get_configuration("BAKER_STARTUP_ARGS", {})
local has_dal_arg = false
for _, arg in ipairs(BAKER_STARTUP_ARGS) do
    -- matches --without-dal
    if arg:match("^%-%-without%-dal$") then
        has_dal_arg = true
        break
    end
    -- matches --with-dal=...
    if arg:match("^%-%-dal%-node$") then
        has_dal_arg = true
        break
    end
end
if not has_dal_arg then
    table.insert(BAKER_STARTUP_ARGS, "--without-dal")
end

am.app.set_model(
    {
        WANTED_BINARIES = wanted_binaries,
        RPC_ADDR = am.app.get_configuration("RPC_ADDR", "127.0.0.1"),
        REMOTE_SIGNER_ADDR = am.app.get_configuration("REMOTE_SIGNER_ADDR", "http://127.0.0.1:20090/"),
		SERVICE_CONFIGURATION = util.merge_tables(
            {
                TimeoutStopSec = 300,
            },
            type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and am.app.get_configuration("SERVICE_CONFIGURATION") or {},
            true
        ),
        BAKER_LOG_LEVEL = am.app.get_configuration("BAKER_LOG_LEVEL", TEZOS_LOG_LEVEL),
        NODE_LOG_LEVEL = am.app.get_configuration("NODE_LOG_LEVEL", TEZOS_LOG_LEVEL),
        VDF_LOG_LEVEL = am.app.get_configuration("VDF_LOG_LEVEL", TEZOS_LOG_LEVEL),
        ACCUSER_LOG_LEVEL = am.app.get_configuration("ACCUSER_LOG_LEVEL", TEZOS_LOG_LEVEL),
        KEY_ALIASES = keys
    },
    { merge = true, overwrite = true }
)
