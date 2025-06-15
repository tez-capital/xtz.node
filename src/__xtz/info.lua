local needs_json_output = am.options.OUTPUT_FORMAT == "json"

local options = ...
local timeout = 4
if options.timeout then
    timeout = tonumber(options.timeout) or timeout
end

local print_chain_info = options.chain
local print_voting_info = options.voting
local print_service_info = options.services
local print_simple = options.simple
local print_all = (not print_voting_info) and (not print_chain_info) and (not print_service_info) and (not print_simple)

local info = {
	level = "ok",
    sync_state = "unknown",
	bootstrapped = false,
    status = "node is operational",
    version = am.app.get_version(),
    type = am.app.get_type(),
	services = {}
}

local is_baker = am.app.get_configuration("NODE_TYPE") == "baker"
if is_baker then
	info.status = "XTZ baker is operational"
end

if print_all or print_service_info or print_simple then
	local service_manager = require"__xtz.service-manager"
	local services = require"__xtz.services"

	local statuses, all_running = service_manager.get_services_status(services.active_names)
	info.services = statuses
	if not all_running then
		info.status = "one or more baker services is not running"
		info.level = "error"
	end
end

local rpc_url = am.app.get_model("LOCAL_RPC_ADDR")
local rest_client = net.RestClient:new(rpc_url, { timeout = timeout })
if print_all or print_chain_info then
	local response, err = rest_client:get("chains/main/blocks/head")
	if response then
		local data = response.data
		local metadata = table.get(data, "metadata")
		info.chain_head = {
			hash = table.get(data, "hash"),
			level = table.get(data, {"header", "level"}),
			timestamp = table.get(data, {"header", "timestamp"}),
			protocol = table.get(metadata, {"protocol"}),
			protocol_next = table.get(metadata, { "next_protocol"}),
			cycle = table.get(metadata, {"level_info", "cycle"}, table.get(metadata, {"level", "cycle"})),
		}
	end

	local response = rest_client:get("network/connections")
	if response then
		info.connections = #response.data
	end
end

if print_all or print_chain_info or print_simple then
	local response = rest_client:get("chains/main/is_bootstrapped")
	if response then
		local data = response.data
		info.bootstrapped = data.bootstrapped
		info.sync_state = data.sync_state
	end
end

if is_baker and (print_all or print_voting_info) then
	local response = rest_client:get("chains/main/blocks/head/votes/proposals")
	if response then
		local data = response.data
		if table.is_array(data) then 
			info.voting_proposals = {}
			for _, v in ipairs(data) do 
				if #v >= 2 and type(info.proposals) == "table" then
					info.proposals[v[1]] = v[2]
				end
			end
		end
	end

	local response = rest_client:get("chains/main/blocks/head/votes/current_period")
	if response  then
		info.voting_current_period = response.data
	end
end

if info.level == "ok" and info.sync_state ~= "synced" then 
	info.level = "warn"
end

if not print_simple and not print_all and (not print_chain_info or not print_service_info) then
	--- reset status and level because we are not able to determine it accurately without 
	--- service and chain information collected
	info.level = nil
	info.status = nil
end

if not print_chain_info and not print_all and not print_simple then
	info.sync_state = nil
end

if needs_json_output then
    print(hjson.stringify_to_json(info, {indent = false}))
else
    print(hjson.stringify(info, {sort_keys = true}))
end