local _appId = am.app.get("id")

local _possibleResidue = {
	_appId .. "-xtz-accuser-next",
	_appId .. "-xtz-baker-next",
	_appId .. "-xtz-endorser",
	_appId .. "-xtz-endorser-next",
	_appId .. "-xtz-vdf-next"
}

local _nodeServices = {
	[_appId .. "-xtz-node"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/node")
}
local _vdfServices = {
	[ _appId .. "-xtz-vdf"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/vdf"),
}
local _bakerServices = {
	[_appId .. "-xtz-accuser"] = am.app.get_configuration("ACCUSER_SERVICE_FILE", "__xtz/assets/accuser"),
	[_appId .. "-xtz-baker"] = am.app.get_configuration("BAKER_SERVICE_FILE", "__xtz/assets/baker"),
}

local _nodeBinaries = { "client", "node" }
local _bakerBinaries = { "accuser", "baker" }
local _vdfBinaries = { "baker" }

if am.app.get_model({ "DOWNLOAD_URLS", "baker-next" }, false) then
	_vdfServices[ _appId .. "xtz-vdf-next"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/vdf")
	_bakerServices[_appId .. "-xtz-baker-next"] = am.app.get_configuration("BAKER_NEXT_SERVICE_FILE", "__xtz/assets/baker-next")
	table.insert(_bakerBinaries, "baker-next")
	table.insert(_vdfBinaries, "baker-next")
end
if am.app.get_model({ "DOWNLOAD_URLS", "accuser-next" }, false) then
	_bakerServices[_appId .. "-xtz-accuser-next"] = am.app.get_configuration("ACCUSER_NEXT_SERVICE_FILE", "__xtz/assets/accuser-next")
	table.insert(_bakerBinaries, "accuser-next")
end

local _nodeServiceNames = {}
for k, _ in pairs(_nodeServices) do
	_nodeServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end
local _bakerServiceNames = {}
for k, _ in pairs(_bakerServices) do
	_bakerServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end
local _vdfServiceNames = {}
for k, _ in pairs(_vdfServices) do
	_vdfServiceNames[k:sub((#(_appId .. "-xtz-") + 1))] = k
end

local _all = util.clone(_nodeServices)
local _allNames = util.clone(_nodeServiceNames)
local _allBinaries = util.clone(_nodeBinaries)

local _isBaker = am.app.get_configuration("NODE_TYPE") == "baker"
if _isBaker then
	for k, v in pairs(_bakerServiceNames) do
		_allNames[k] = v
	end
	for k, v in pairs(_bakerServices) do
		_all[k] = v
	end
	for _, v in ipairs(_bakerBinaries) do
		if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
			table.insert(_allBinaries, v)
		end
	end
end

local _isVdf = am.app.get_configuration("NODE_TYPE") == "vdf"
if _isVdf then
	for k, v in pairs(_vdfServiceNames) do
		_allNames[k] = v
	end
	for k, v in pairs(_vdfServices) do
		_all[k] = v
	end
	for _, v in ipairs(_vdfBinaries) do
		if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
			table.insert(_allBinaries, v)
		end
	end
end

-- includes potential residues
local function _remove_all_services()
	local serviceManager = require"__xtz.service-manager"

	local all = util.merge_arrays(table.values(_bakerServiceNames), table.values(_nodeServiceNames))
	all = util.merge_arrays(all, table.values(_vdfServiceNames))
	all = util.merge_arrays(all, _possibleResidue)

	for _, service in ipairs(all) do
		if type(service) ~= "string" then goto CONTINUE end
		local _ok, _error = serviceManager.safe_remove_service(service)
		if not _ok then
			ami_error("Failed to remove " .. service .. ": " .. (_error or ""))
		end
		::CONTINUE::
	end
end

return {
	all = _all,
	allNames = _allNames,
	allBinaries = _allBinaries,
	remove_all_services = _remove_all_services
}