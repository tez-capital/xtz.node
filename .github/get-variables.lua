local hjson = require"hjson"
local io = require"io"

local specsContent = fs.read_file("./src/specs.json")
local specs = hjson.parse(specsContent)

print("ID=" .. specs.id)
print("VERSION=" .. specs.version)

local containerTag = string.match(specs.version, "(%d+.%d+.%d+)")
print("CONTAINER_TAG=" .. containerTag)

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