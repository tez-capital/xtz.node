local _args = table.pack(...)

ami_assert(#_args > 0, "Please provide baker address...")
local _importArgs = { "import", "secret", "key", "baker", am.app.get_model("REMOTE_SIGNER_ADDR", "http://127.0.0.1:2222/") .. _args[1] }

for _, v in ipairs(_args) do
	if string.trim(v) == "-f" or string.trim(v) == "--force" then
		table.insert(_importArgs, "--force")
		break
	end
end


local _user = am.app.get("user")
local _proc = proc.spawn("bin/client", _importArgs, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key!")