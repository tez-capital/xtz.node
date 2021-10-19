local _ok, _systemctl = am.plugin.safe_get("systemctl")
ami_assert(_ok, "Failed to load systemctl plugin")

local _isBaker = am.app.get_configuration("NODE_TYPE") == "baker"

local _toStart = {
	am.app.get("id") .. "-xtz-node",
	_isBaker and am.app.get("id") .. "-xtz-baker",
	_isBaker and am.app.get("id") .. "-xtz-endorser",
	_isBaker and am.app.get("id") .. "-xtz-accuser",
	_isBaker and am.app.get_model({ "AVAILABLE_NEXT", "baker" }, false) and (am.app.get("id") .. "-xtz-baker-next"),
	_isBaker and am.app.get_model({ "AVAILABLE_NEXT", "endorser" }, false) and ( am.app.get("id") .. "-xtz-endorser-next"),
	_isBaker and am.app.get_model({ "AVAILABLE_NEXT", "accuser" }, false) and (am.app.get("id") .. "-xtz-accuser-next")
}

for _, service in ipairs(_toStart) do
	-- skip false values
	if type(service) ~= "string" then goto CONTINUE end
	local _ok, _error = _systemctl.safe_remove_service(service)
	if not _ok then
		ami_error("Failed to remove " .. service .. ".service " .. (_error or ""))
	end
	::CONTINUE::
end

log_success("Node services succesfully removed.")