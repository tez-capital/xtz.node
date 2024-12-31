local args = table.pack(...)

ami_assert(#args > 0, "Please provide baker address...")
local alias = "baker"
local force = false
for _, v in ipairs(args) do
	if string.trim(v) == "-f" or string.trim(v) == "--force" then
		force = true
	end
	if string.trim(v):sub(1, 3) == "-a=" then
		alias = string.trim(v):sub(4)
	elseif string.trim(v):sub(1, 8) == "--alias=" then
		alias = string.trim(v):sub(9)
	end
end

local import_args = { "-p", "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK", "--remote-signer", am.app.get_model("REMOTE_SIGNER_ADDR", "http://127.0.0.1:20090/"), "import", "secret", "key", alias, "remote:" .. args[1] }
if force then
	table.insert(import_args, "--force")
end

local process = proc.spawn("bin/client", import_args, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
ami_assert(process.exit_code == 0,  "Failed to import key!")