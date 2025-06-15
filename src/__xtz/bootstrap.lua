local args = table.pack(...)

if table.includes(args, "--help") then
	print("Usage: ... bootstrap <url> [block hash] [--no-check]")
	return
end

local no_check = false
if table.includes(args, "--no-check") then
	args = table.filter(args, function(k, v) return v ~= "--no-check" and k ~= "n" end)
	no_check = true
end

ami_assert(#args >= 1, [[Please provide URL to snapshot source and block hash to import.
ami ... bootstrap <url> [block hash]])

-- check if node is running
local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"
assert(not service_manager.has_any_service_status(services.active_names, "running"),
	"node services are running, please stop them first. Use `ami xtz stop` to stop them.")

log_info"Preparing the snapshot import"
-- cleanup directory
local node_directory = "./data/.tezos-node"
local tmp_node_directory = "./data/.tezos-node-tmp"
if not fs.exists(tmp_node_directory) and fs.exists(node_directory) then
	os.rename(node_directory, tmp_node_directory)
	fs.mkdirp(node_directory)
	fs.copy_file(path.combine(tmp_node_directory, "config.json"), path.combine(node_directory, "config.json"))
	fs.copy_file(path.combine(tmp_node_directory, "identity.json"), path.combine(node_directory, "identity.json"))
end
-- make sure we have all required directories in place
fs.mkdirp(tmp_node_directory)
fs.mkdirp(node_directory)

local paths_to_remove = {
	"context",
	"daily_logs",
	"lock",
	"store",
	-- we want to preserve + proofs
	-- "identity.json",
	-- "config.json",
	-- "peers.json",
	-- "version.json",
}
local node_directory_content = fs.read_dir(tmp_node_directory, { return_full_paths = false, recurse = false, as_dir_entries = false })
local paths_to_keep = table.filter(node_directory_content, function (_, v)
	return not table.includes(paths_to_remove, v)
end)

-- bootstrap
local tmp_bootstrap_file = "./data/tmp-snapshot"
local exists = fs.exists(args[1])
if exists then
	tmp_bootstrap_file = args[1]
else
	log_info("Downloading " .. tostring(args[1]) .. "...")
	local ok, err = net.download_file(args[1], tmp_bootstrap_file, {follow_redirects = true, content_type = "binary/octet-stream", progress_function = (function ()
		local last_written = 0
		return function(total, current) 
			local progress = math.floor(current / total * 100)
			if math.fmod(progress, 10) == 0 and last_written ~= progress then 
				last_written = progress
				io.write(progress .. "%...")
				io.flush()
				if progress == 100 then print() end
			end
		end
	end)()})
	if not ok then
		fs.remove(tmp_bootstrap_file)
		ami_error("Failed to download: " .. tostring(err))
	end
end

local import_args = { "snapshot", "import", tmp_bootstrap_file }
if no_check then
	table.insert(import_args, "--no-check")
end
if #args > 1 then
	table.insert(import_args, "--block")
	table.insert(import_args, args[2])
end
local bootstrap_process = proc.spawn("./bin/node", import_args, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd() --[[@as string]], "data") }
})
os.remove(tmp_bootstrap_file)
ami_assert(bootstrap_process.exit_code == 0,  "Failed to import snapshot!")

log_info"finishing the snapshot import"
for _, v in ipairs(paths_to_keep) do
	os.rename(path.combine(tmp_node_directory, v --[[@as string]]), path.combine(node_directory, v --[[@as string]]))
end
fs.remove(tmp_node_directory, { recurse = true })

require"__xtz.base_utils".setup_file_ownership()

log_success("snapshot imported.")
