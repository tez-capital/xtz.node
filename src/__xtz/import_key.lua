local _args = table.pack(...)

ami_assert(#_args > 0, "Please provide baker address...")
local _alias = "baker"
local _force = false
for _, v in ipairs(_args) do
	if string.trim(v) == "-f" or string.trim(v) == "--force" then
		_force = true
	end
	if string.trim(v):sub(1, 3) == "-a=" then
		_alias = string.trim(v):sub(4)
	elseif string.trim(v):sub(1, 8) == "--alias=" then
		_alias = string.trim(v):sub(9)
	end
end

local _importArgs = { "--remote-signer", am.app.get_model("REMOTE_SIGNER_ADDR", "http://127.0.0.1:2222/"), "import", "secret", "key", _alias, "remote:" .. _args[1] }
if _force then
	table.insert(_importArgs, "--force")
end

local _proc = proc.spawn("bin/client", _importArgs, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key!")