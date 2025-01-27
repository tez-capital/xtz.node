local app_id = am.app.get("id")

local possible_residue = {
	app_id .. "-xtz-accuser-next",
	app_id .. "-xtz-baker-next",
	app_id .. "-xtz-endorser",
	app_id .. "-xtz-endorser-next",
	app_id .. "-xtz-vdf-next"
}

local node_services = {
	[app_id .. "-xtz-node"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/node")
}
local vdf_services = {
	[ app_id .. "-xtz-vdf"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/vdf"),
}
local baker_services = {
	[app_id .. "-xtz-accuser"] = am.app.get_configuration("ACCUSER_SERVICE_FILE", "__xtz/assets/accuser"),
	[app_id .. "-xtz-baker"] = am.app.get_configuration("BAKER_SERVICE_FILE", "__xtz/assets/baker"),
}
local prism_services = {
	[app_id .. "-xtz-prism-server"] = "__xtz/assets/prism"
}

local node_binaries = { "client", "node" }
local baker_binaries = { "accuser", "baker" }
local vdf_binaries = { "baker" }

if am.app.get_model({ "DOWNLOAD_URLS", "baker-next" }, false) then
	vdf_services[ app_id .. "xtz-vdf-next"] = am.app.get_configuration("NODE_SERVICE_FILE", "__xtz/assets/vdf")
	baker_services[app_id .. "-xtz-baker-next"] = am.app.get_configuration("BAKER_NEXT_SERVICE_FILE", "__xtz/assets/baker-next")
	table.insert(baker_binaries, "baker-next")
	table.insert(vdf_binaries, "baker-next")
end
if am.app.get_model({ "DOWNLOAD_URLS", "accuser-next" }, false) then
	baker_services[app_id .. "-xtz-accuser-next"] = am.app.get_configuration("ACCUSER_NEXT_SERVICE_FILE", "__xtz/assets/accuser-next")
	table.insert(baker_binaries, "accuser-next")
end

local node_service_names = {}
for k, _ in pairs(node_services) do
	node_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
local baker_service_names = {}
for k, _ in pairs(baker_services) do
	baker_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
local vdf_service_names = {}
for k, _ in pairs(vdf_services) do
	vdf_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end
local prism_service_names = {}
for k, _ in pairs(prism_services) do
	prism_service_names[k:sub((#(app_id .. "-xtz-") + 1))] = k
end

local all = util.clone(node_services)
local all_names = util.clone(node_service_names)
local all_binaries = util.clone(node_binaries)

local is_baker = am.app.get_configuration("NODE_TYPE") == "baker"
if is_baker then
	for k, v in pairs(baker_service_names) do
		all_names[k] = v
	end
	for k, v in pairs(baker_services) do
		all[k] = v
	end
	for _, v in ipairs(baker_binaries) do
		if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
			table.insert(all_binaries, v)
		end
	end
end

local is_vdf = am.app.get_configuration("NODE_TYPE") == "vdf"
if is_vdf then
	for k, v in pairs(vdf_service_names) do
		all_names[k] = v
	end
	for k, v in pairs(vdf_services) do
		all[k] = v
	end
	for _, v in ipairs(vdf_binaries) do
		if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
			table.insert(all_binaries, v)
		end
	end
end

local uses_prism = am.app.get_configuration("PRISM")
if uses_prism then
	for k, v in pairs(prism_service_names) do
		all_names[k] = v
	end
	for k, v in pairs(prism_services) do
		all[k] = v
	end
	table.insert(all_binaries, "prism")
end

-- includes potential residues
local function remove_all_services()
	local service_manager = require"__xtz.service-manager"

	local all = util.merge_arrays(table.values(baker_service_names), table.values(node_service_names))
	all = util.merge_arrays(all, table.values(vdf_service_names))
	all = util.merge_arrays(all, table.values(prism_service_names))
	all = util.merge_arrays(all, possible_residue)

	for _, service in ipairs(all) do
		if type(service) ~= "string" then goto CONTINUE end
		local ok, err = service_manager.safe_remove_service(service)
		if not ok then
			ami_error("Failed to remove " .. service .. ": " .. (err or ""))
		end
		::CONTINUE::
	end
end

return {
	all = all,
	all_names = all_names,
	all_binaries = all_binaries,
	remove_all_services = remove_all_services
}