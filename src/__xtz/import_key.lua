local _args = table.pack(...)

ami_assert(#_args > 0, "Please provide signer address in format: http://X.X.X.X:2222/<xtz address>")

local _user = am.app.get("user")
local _proc = proc.spawn("bin/client", { "import", "secret", "key", "baker", ... }, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key!")