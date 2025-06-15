local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

service_manager.remove_services(services.cleanup_names)

log_success("node services successfully removed.")