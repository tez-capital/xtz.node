local hjson = require"hjson"
local io = require"io"

local specs_raw = fs.read_file("./src/specs.json")
local specs = hjson.parse(specs_raw)

print("ID=" .. specs.id)
print("VERSION=" .. specs.version)

local container_tag = string.match(specs.version, "(%d+.%d+.%d+)")
print("CONTAINER_TAG=" .. container_tag)

local command = 'git tag -l "' .. specs.version .. '"'
local handle = io.popen(command)
if not handle then
	error("failed to check existing versions")
end
local result = handle:read("*a")
handle:close()

if result == "" then
	print("NEEDS_RELEASE=true")
end