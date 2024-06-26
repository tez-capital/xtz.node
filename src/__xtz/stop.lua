local serviceManager = require"__xtz.service-manager"
local services = require"__xtz.services"

log_info("Stopping node services... this may take a few minutes.")
for _, service in pairs(services.allNames) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = serviceManager.safe_stop_service(service)
	ami_assert(_ok, "Failed to stop " .. service .. ": " .. (_error or ""))
	::CONTINUE::
end

log_success("Node services succesfully stopped.")