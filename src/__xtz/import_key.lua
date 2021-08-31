local _args = table.pack(...)

ami_assert(#_args > 0, "Please provide signer address in format: tcp://X.X.X.X:22222/<xtz address>")

local _user = am.app.get("user")
local _proc = proc.spawn("bin/client", { "import", "secret", "key", "baker", _args[1] }, {
	stdio = "inherit",
	wait = true,
	env = { HOME = _user == "root" and "/root" or "/home/" .. _user }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key!")