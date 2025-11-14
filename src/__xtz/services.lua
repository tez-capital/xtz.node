local app_id = am.app.get("id")

local possible_residue = {
	app_id .. "-xtz-accuser-next",
	app_id .. "-xtz-baker-next",
	app_id .. "-xtz-endorser",
	app_id .. "-xtz-endorser-next",
	app_id .. "-xtz-vdf-next",
	app_id .. "-xtz-prism-server"
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
	[app_id .. "-xtz-prism"] = "__xtz/assets/prism"
}

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

local active_services = util.clone(node_services)
local active_names = util.clone(node_service_names)

local is_baker = am.app.get_configuration("NODE_TYPE") == "baker"
if is_baker then
	for k, v in pairs(baker_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(baker_services) do
		active_services[k] = v
	end
end

local is_vdf = am.app.get_configuration("NODE_TYPE") == "vdf"
if is_vdf then
	for k, v in pairs(vdf_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(vdf_services) do
		active_services[k] = v
	end
end

local uses_prism = am.app.get_configuration("PRISM")
if uses_prism then
	for k, v in pairs(prism_service_names) do
		active_names[k] = v
	end
	for k, v in pairs(prism_services) do
		active_services[k] = v
	end
end


---@type string[]
local cleanup_names = {}
cleanup_names = util.merge_arrays(cleanup_names, table.values(node_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(baker_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(vdf_service_names))
cleanup_names = util.merge_arrays(cleanup_names, table.values(prism_service_names))
cleanup_names = util.merge_arrays(cleanup_names, possible_residue)

return {
	active = active_services,
	active_names = active_names,
	cleanup_names = cleanup_names,
}