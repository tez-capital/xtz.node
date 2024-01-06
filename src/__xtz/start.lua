local backend = am.app.get_configuration("backend", os.getenv("ASCEND_SERVICES") ~= nil and "ascend" or "systemd")

local serviceManager = nil
if backend == "ascend" then
	local ok, asctl = am.plugin.safe_get("asctl")
	ami_assert(ok, "Failed to load asctl plugin")
	serviceManager = asctl
else
	local ok, systemctl = am.plugin.safe_get("systemctl")
	ami_assert(ok, "Failed to load systemctl plugin")
	serviceManager = systemctl
end

local services = require"__xtz.services"

for _, service in pairs(services.allNames) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = serviceManager.safe_start_service(service)
	ami_assert(_ok, "Failed to start " .. service .. ": " .. (_error or ""))
	::CONTINUE::
end

log_success("Node services succesfully started.")