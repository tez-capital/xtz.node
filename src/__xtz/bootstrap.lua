local _args = table.pack(...)

local _user = am.app.get("user")
ami_assert(type(_user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

ami_assert(#_args > 1, [[Please provide URL to snapshot source and block hash to import.
ami ... bootstrap <url> <block hash>]])

local _tmpFile = os.tmpname() 
local _ok, _exists = fs.safe_exists(_args[1])
if _ok and _exists then
	_tmpFile = _args[1]
else
	log_info("Downloading " .. tostring(_args[1]) .. "...")
	local _ok, _error = net.safe_download_file(_args[1], _tmpFile, {followRedirects = true, contentType = "binary/octet-stream", progressFunction = (function ()
		local _lastWritten = 0
		return function(total, current) 
			local _progress = math.floor(current / total * 100)
			if math.fmod(_progress, 10) == 0 and _lastWritten ~= _progress then 
				_lastWritten = _progress
				io.write(_progress .. "%...")
				io.flush()
				if _progress == 100 then print() end
			end
		end
	end)()})
	if not _ok then
		fs.remove(_tmpFile)
		ami_error("Failed to download: " .. tostring(_error))
	end
end

local _args = table.pack(...)
local _proc = proc.spawn("./bin/node", { "snapshot", "import", _tmpFile, "--block", _args[2]}, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd(), "data") }
})
os.remove(_tmpFile)
ami_assert(_proc.exitcode == 0,  "Failed to import snapshot!")

local _ok, _uid = fs.safe_getuid(_user)
ami_assert(_ok, "Failed to get " .. _user .. "uid - " .. (_uid or ""))
local _ok, _error = fs.safe_chown("data", _uid, _uid, {recurse = true})
if not _ok then
	ami_error(_ok, "Failed to chown data - " .. _error)
end

log_success("Snapshot imported.")
