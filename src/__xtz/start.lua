local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

for _, service in pairs(services.all_names) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local ok, err = service_manager.safe_start_service(service)
	ami_assert(ok, "Failed to start " .. service .. ": " .. (err or ""))
	::CONTINUE::
end

log_success("Node services succesfully started.")