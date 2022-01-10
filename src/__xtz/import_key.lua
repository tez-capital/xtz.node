local _args = table.pack(...)

ami_assert(#_args > 0, "Please provide baker address...")

local _user = am.app.get("user")
local _proc = proc.spawn("bin/client", { "import", "secret", "key", "baker", am.app.get_model("REMOTE_SIGNER_ADDR", "tcp://127.0.0.1:2222/") .. _args[1] }, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
ami_assert(_proc.exitcode == 0,  "Failed to import key!")