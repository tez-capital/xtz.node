local _json = am.options.OUTPUT_FORMAT == "json"
local _appId = am.app.get("id", "unknown")

local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin", EXIT_PLUGIN_LOAD_ERROR)

local _serviceName = am.app.get_model("SERVICE_NAME", "unknown")
local _ok, _status, _started = _systemctl.safe_get_service_status(_appId .. "-" .. _serviceName)
ami_assert(_ok, "Failed to get status of " .. _appId .. "-" .. _serviceName .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)

local _info = {
    level = "ok",
    sync_state = false,
	bootstrapped = false,
    status = "XTZ baker is operational",
    version = am.app.get_version(),
    type = am.app.get_type()
}

local _isBaker = am.app.get_configuration("NODE_TYPE") == "baker"
local _services = {
	node = am.app.get("id") .. "-xtz-node",
	baker = _isBaker and am.app.get("id") .. "-xtz-baker",
	endorser = _isBaker and am.app.get("id") .. "-xtz-endorser",
	accuser = _isBaker and am.app.get("id") .. "-xtz-accuser",
	["baker-next"] = _isBaker and am.app.get_model({ "AVAILABLE_NEXT", "baker" }, false) and (am.app.get("id") .. "-xtz-baker-next"),
	["endorser-next"] = _isBaker and am.app.get_model({ "AVAILABLE_NEXT", "endorser" }, false) and ( am.app.get("id") .. "-xtz-endorser-next"),
	["accuser-next"] = _isBaker and am.app.get_model({ "AVAILABLE_NEXT", "accuser" }, false) and (am.app.get("id") .. "-xtz-accuser-next")
}

for k, v in pairs(_services) do 
	if type(v) ~= "string" then goto CONTINUE end
	local _ok, _status, _started = _systemctl.safe_get_service_status(v)
	ami_assert(_ok, "Failed to get status of " .. v .. ".service " .. (_status or ""), EXIT_PLUGIN_EXEC_ERROR)
	_info[k] = _status
	_info[k .. "_started"] = _started
	if _status ~= "running" then 
		_info.status = "One or more baker services is not running"
		_info.level = "error"
	end
	::CONTINUE::
end

local _client = net.RestClient:new("http://localhost:8732/", { timeout = 2 })
local _ok, _response = _client:safe_get("chains/main/blocks/head")
if _ok then
	local _data = _response.data
	local _metadata = table.get(_data, "metadata")
	_info.chain_head = {
		hash = table.get(_data, "hash"),
		level = table.get(_data, {"header", "level"}),
		timestamp = table.get(_data, {"header", "timestamp"}),
		protocol = table.get(_metadata, {"protocol"}),
		protocol_next = table.get(_metadata, { "next_protocol"}),
		cycle = table.get(_metadata, {"level_info", "cycle"}, table.get(_metadata, {"level", "cycle"})),
	}
end

local _ok, _response = _client:safe_get("network/connections")
if _ok then
	_info.connections = #_response.data
end

local _ok, _response = _client:safe_get("chains/main/is_bootstrapped")
if _ok then
	local _data = _response.data
	_info.bootstrapped = _data.bootstrapped
	_info.sync_state = _data.sync_state
end

local _ok, _response = _client:safe_get("chains/main/is_bootstrapped")
if _ok then
	local _data = _response.data
	_info.bootstrapped = _data.bootstrapped
	_info.sync_state = _data.sync_state
end

if _isBaker then
	-- local _cycle = table.get(_info, {"chain_head", "cycle"})
	-- local _ok, _pkhFile = fs.safe_read_file("data/.tezos-client/public_key_hashs")
	-- local _ok2, _pkh = hjson.safe_parse(_pkhFile)
	-- if _ok and _ok2 then 
	-- 	local _bakerKeyHash = nil
	-- 	for _, v in ipairs(_pkh) do 
	-- 		if v.name == "baker" then 
	-- 			_bakerKeyHash = v.value
	-- 		end
	-- 	end
	-- 	if type(_bakerKeyHash) == "string" and type(_cycle) == "number" then
	-- 		local _ok, _response = _client:safe_get("chains/main/blocks/head/helpers/baking_rights?delegate=".._bakerKeyHash.."&max_priority=1&cycle="..tostring(_cycle))
	-- 		if _ok then
	-- 			_info.baking_rights = _response.data
	-- 			_info.baking_rights_status = {
	-- 				level = "ok",
	-- 				status = "Collected."
	-- 			}
	-- 		else
	-- 			_info.baking_rights = {}
	-- 			_info.baking_rights_status = {
	-- 				level = "error",
	-- 				status = "Failed to obtain rights from the node!",
	-- 				response = _response
	-- 			}
	-- 		end
	-- 	else
	-- 		_info.baking_rights = {}
	-- 		_info.baking_rights_status = {
	-- 			level = "error",
	-- 			status = "Invalid baker key hash or cycle number!",
	-- 			bakerKeyHash = _bakerKeyHash,
	-- 			cycle = _cycle
	-- 		}
	-- 	end
	-- else
	-- 	_info.baking_rights = {}
	-- 	_info.baking_rights_status = {
	-- 		level = "error",
	-- 		status = "Failed to read baker key hash!",
	-- 		file = _pkhFile,
	-- 		parsed = _pkh
	-- 	}
	-- end

	local _ok, _response = _client:safe_get("chains/main/blocks/head/votes/proposals")
	if _ok then
		local _data = _response.data
		if table.is_array(_data) then 
			_info.voting_proposals = {}
			for _, v in ipairs(_data) do 
				if #v >= 2 then
					_info.proposals[v[1]] = v[2]
				end
			end
		end
	end

	local _ok, _response = _client:safe_get("chains/main/blocks/head/votes/current_period")
	if _ok then
		_info.voting_current_period = _response.data
	end
end


if _info.level == "ok" and _info.sync_state ~= "synced" then 
	_info.level = "warn"
end

if _json then
    print(hjson.stringify_to_json(_info, {indent = false}))
else
    print(hjson.stringify(_info, {sortKeys = true}))
end