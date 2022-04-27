local _appId = am.app.get("id")

local _possibleResidue = {
	_appId .. "-xtz-accuser-next",
	_appId .. "-xtz-baker-next",
	_appId .. "-xtz-endorser",
	_appId .. "-xtz-endorser-next"
}

local _nodeServices = {
	[_appId .. "-xtz-node"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/node.service")
}

local _bakerServices = {
	[_appId .. "-xtz-accuser"] = am.app.get_configuration("ACCUSER_SERVICE_FILE", "__xtz/assets/accuser.service"),
	[_appId .. "-xtz-baker"] = am.app.get_configuration("BAKER_SERVICE_FILE", "__xtz/assets/baker.service"),
	-- [_appId .. "-xtz-endorser"] = am.app.get_configuration("ENDORSER_SERVICE_FILE", "__xtz/assets/endorser.service"),

	[_appId .. "-xtz-accuser-next"] = am.app.get_configuration("ACCUSER_NEXT_SERVICE_FILE", "__xtz/assets/accuser-next.service"),
	[_appId .. "-xtz-baker-next"] = am.app.get_configuration("BAKER_NEXT_SERVICE_FILE", "__xtz/assets/baker-next.service"),
	-- [_appId .. "-xtz-endorser-next"] = am.app.get_configuration("ENDORSER_NEXT_SERVICE_FILE", "__xtz/assets/endorser-next.service"),
}

for k, _ in pairs(_bakerServices) do
	local _fileId = k:sub((#(_appId .. "-xtz-") + 1))
	if not am.app.get_model({ "DOWNLOAD_URLS", _fileId }, false) then
		_bakerServices[k] = nil
	end
end

local _nodeServiceNames = {}
for k, _ in pairs(_nodeServices) do
	_nodeServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end

local _bakerServiceNames = {}
for k, _ in pairs(_bakerServices) do
	_bakerServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end

local _allNames = util.clone(_nodeServiceNames)

local _isBaker = am.app.get_configuration("NODE_TYPE") == "baker"
if _isBaker then
	for k, v in pairs(_bakerServiceNames) do
		_allNames[k] = v
	end
end

-- includes potential residues
local function _remove_all_services()
	local _all = util.merge_arrays(table.values(_bakerServiceNames), table.values(_nodeServiceNames))
	_all = util.merge_arrays(_all, _possibleResidue)

	local _ok, _systemctl = am.plugin.safe_get("systemctl")
	ami_assert(_ok, "Failed to load systemctl plugin")

	for _, service in ipairs(_all) do
		if type(service) ~= "string" then goto CONTINUE end
		local _ok, _error = _systemctl.safe_remove_service(service)
		if not _ok then
			ami_error("Failed to remove " .. service .. ".service " .. (_error or ""))
		end
		::CONTINUE::
	end
end

return {
	node = _nodeServices,
	baker = _bakerServices,
	allNames = _allNames,
	nodeServiceNames = _nodeServiceNames,
	bakerServiceNames = _bakerServiceNames,
	remove_all_services = _remove_all_services
}