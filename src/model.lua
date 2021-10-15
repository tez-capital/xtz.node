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

local _downloadLinks = {
	["linux-x86_x64"] = {
		node = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/x86_64-tezos-node",
		client = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/x86_64-tezos-client",
		
		accuser = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/x86_64-tezos-accuser-010-PtGRANAD",
		baker = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/x86_64-tezos-baker-010-PtGRANAD",
		endorser = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/x86_64-tezos-endorser-010-PtGRANAD",
		
		-- ["accuser-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/x86_64-tezos-accuser-010-PtGRANAD",
		-- ["baker-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/x86_64-tezos-baker-010-PtGRANAD",
		-- ["endorser-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/x86_64-tezos-endorser-010-PtGRANAD"
		
	},
    ["linux-arm64"] = {
		node = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/arm64-tezos-node",
		client = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/arm64-tezos-client",
		
		accuser = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/arm64-tezos-accuser-010-PtGRANAD",
		baker = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/arm64-tezos-baker-010-PtGRANAD",
		endorser = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.7.0/arm64-tezos-endorser-010-PtGRANAD",
		
		-- ["accuser-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/arm64-tezos-accuser-010-PtGRANAD",
		-- ["baker-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/arm64-tezos-baker-010-PtGRANAD",
		-- ["endorser-next"] = "https://gitlab.com/api/v4/projects/3836952/packages/generic/tezos/9.6.0/arm64-tezos-endorser-010-PtGRANAD"
	}
}

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

am.app.set_model({
		DOWNLOAD_URLS = _downlaodUrls, 
		WANTED_BINARIES = {
			"node", "client", "accuser", "baker", "endorser", "accuser-next", "baker-next", "endorser-next"
		},
		AVAILABLE_NEXT = {
			accuser = type(_downlaodUrls["accuser-next"]) == "string",
			baker = type(_downlaodUrls["baker-next"]) == "string",
			endorser = type(_downlaodUrls["endorser-next"]) == "string"
		}
	}, 
	{merge = true, overwrite = true}
)


local _dataDir = path.combine(os.cwd(), "data")

am.app.set_model(
    {
        RPC_ADDR = am.app.get_configuration("RPC_ADDR", "127.0.0.1"),
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
