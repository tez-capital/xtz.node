local function help()
	print("Usage: ... bootstrap <url> [block hash] [--no-check] [--force]")
	print("  <url> - URL to the snapshot source, can be a local file or remote URL.")
	print("  [block hash] - Optional block hash to import the snapshot at.")
	print("  --no-check - Skip the integrity check of the snapshot.")
end

-- process args
local args = table.pack(...)
if table.includes(args, "--help") then return help() end

local no_check = false
if table.includes(args, "--no-check") then
	args = table.filter(args, function(k, v) return v ~= "--no-check" and k ~= "n" end)
	no_check = true
end

local keep_snapshot = false
if table.includes(args, "--keep-snapshot") then
	args = table.filter(args, function(k, v) return v ~= "--keep-snapshot" and k ~= "k" end)
	keep_snapshot = true
end

local block_id = nil
if #args > 1 then
	block_id = args[2]
end

if #args == 0 then
	log_error("Invalid arguments. Please provide URL to snapshot source and block hash to import.")
	return help()
end

-- check if node is running
local service_manager = require "__xtz.service-manager"
local services = require "__xtz.services"
ami_assert(not service_manager.has_any_service_status(services.active_names, "running"),
	"node services are running, please stop them first. Use `ami stop` to stop them.")

log_info "Preparing the snapshot import"
-- cleanup directory
local node_directory = "./data/.tezos-node"
local tmp_node_directory = "./data/.tezos-node-tmp"
local existing_node_data_available = false
if fs.exists(node_directory) then
	-- we move the existing node directory to a temporary one
	-- so that we can restore important files later
	existing_node_data_available = true
	fs.remove(tmp_node_directory, { recurse = true }) -- remove any previous tmp directory
	os.rename(node_directory, tmp_node_directory)
	fs.mkdirp(node_directory)
	fs.copy_file(path.combine(tmp_node_directory, "config.json"), path.combine(node_directory, "config.json"))
	fs.copy_file(path.combine(tmp_node_directory, "identity.json"), path.combine(node_directory, "identity.json"))
end
-- make sure we have all required directories in place
fs.mkdirp(tmp_node_directory)
fs.mkdirp(node_directory)

local paths_to_remove = { "context", "daily_logs", "lock", "store" }
-- we want to preserve "identity.json", "config.json", "peers.json", "version.json" and anything else that might be important
local node_directory_content = fs.read_dir(tmp_node_directory,
	{ return_full_paths = false, recurse = false, as_dir_entries = false }) --[=[@as string[]]=]
local paths_to_keep = table.filter(node_directory_content, function(_, v)
	return not table.includes(paths_to_remove, v)
end)

local downloaded_bootstrap_file = "./data/tmp-snapshot"
local using_local_bootstrap_file = false
if fs.exists(args[1]) then -- bootstrap from local file
	downloaded_bootstrap_file = args[1]
	using_local_bootstrap_file = true
end

-- bootstrap
if not using_local_bootstrap_file then
	log_info("Downloading " .. tostring(args[1]) .. "...")
	local ok, err = net.download_file(args[1], downloaded_bootstrap_file,
		{
			follow_redirects = true,
			content_type = "binary/octet-stream",
			progress_function = (function()
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
			end)()
		})
	if not ok then
		fs.remove(downloaded_bootstrap_file)
		ami_error("Failed to download: " .. tostring(err))
	end
end

local import_args = { "snapshot", "import", downloaded_bootstrap_file }
if no_check then
	table.insert(import_args, "--no-check")
end
if block_id then
	table.insert(import_args, "--block")
	table.insert(import_args, block_id)
end

local bootstrap_process, err = proc.spawn("./bin/node", import_args, {
	stdio = "inherit",
	wait = true,
	env = { HOME = path.combine(os.cwd() --[[@as string]], "data") },
	username = am.app.get("user")
})
if not using_local_bootstrap_file and not keep_snapshot then -- remove the bootstrap file if it was downloaded
	os.remove(downloaded_bootstrap_file)
end
if not bootstrap_process or bootstrap_process.exit_code ~= 0 then -- restore entire node directory if failed
	log_info("snapshot import failed, restoring previous node data directory")
	fs.remove(node_directory, { recurse = true })
	os.rename(tmp_node_directory, node_directory)
elseif existing_node_data_available then
	log_info("restoring important files from the previous node data directory")
	for _, v in ipairs(paths_to_keep) do
		os.rename(path.combine(tmp_node_directory, v --[[@as string]]), path.combine(node_directory, v --[[@as string]]))
	end
	fs.remove(tmp_node_directory, { recurse = true })
end

ami_assert(bootstrap_process, "failed to spawn node process: " .. tostring(err))
ami_assert(bootstrap_process.exit_code == 0, "failed to import snapshot")

log_info "finishing the snapshot import"

require "__xtz.base_utils".setup_file_ownership()

log_success("snapshot imported")
