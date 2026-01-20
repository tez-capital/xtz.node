-- SOURCE: https://octez.tezos.com/releases
-- usage:
-- eli src/__xtz/update-sources.lua
-- eli src/__xtz/update-sources.lua latest
-- eli src/__xtz/update-sources.lua octez-v24.0

local hjson = require "hjson"
local args = table.pack(...)

local target_version = args[1]

local net = require "http"

if not target_version or target_version == "latest" then
	print("Fetching latest version from RSS feed...")
	local response = net.download_string("https://octez.tezos.com/releases/feed.xml", {
		read_timeout = 1000,
		write_timeout = 1000,
		connect_timeout = 1000,
		retry_limit = 3,
		follow_redirects = true,
		headers = {
			-- ["Connection"] = "close"
		}
	})
	print "got response"
	if #response == 0 then
		print("Empty response for feed.xml")
		return
	end

	-- Parse <guid> ... </guid>
	for guid in response:gmatch("<guid>%s*(octez%-v[%d%.%-rc]+)%s*</guid>") do
		target_version = guid
	end

	if not target_version or target_version == "latest" then
		print("No version found in feed.xml")
		return
	end
end

print("Target version: " .. target_version)

local arch_map = {
	["linux-x86_64"] = "x86_64",
	["linux-arm64"] = "arm64"
}

local current_sources = hjson.parse(fs.read_file("src/__xtz/sources.hjson"))
local new_sources_map = {}

-- Update Linux sources
for platform, arch_name in pairs(arch_map) do
	print("Updating " .. platform .. "...")
	local bin_arch = arch_name
	-- https://octez.tezos.com/releases/octez-v24.0/binaries/x86_64/sha256sums.txt
	local sha_url = "https://octez.tezos.com/releases/" ..
		target_version .. "/binaries/" .. bin_arch .. "/sha256sums.txt"

	local sums_content = net.download_string(sha_url, {
		read_timeout = 1000,
		write_timeout = 1000,
		connect_timeout = 1000,
		retry_limit = 3,
		follow_redirects = true,
		headers = {
			-- ["Connection"] = "close"
		}
	})
	if #sums_content == 0 then
		print("Failed to download sha256sums for " .. platform)
		-- Don't return, maybe macos works? Or should we fail hard?
		-- Let's fail hard for safety
		return
	end

	print("Found sha256sums for " .. platform)
	local new_platform_sources = {}
	-- Copy prism if exists
	if current_sources[platform] and current_sources[platform].prism then
		new_platform_sources.prism = current_sources[platform].prism
	end

	-- Parse sha256sums
	for line in sums_content:gmatch("[^\r\n]+") do
		local hash, filename = line:match("(%x+)%s+(.+)")
		if hash and filename then
			local key = nil
			if filename == "octez-node" then
				key = "node"
			elseif filename == "octez-client" then
				key = "client"
			elseif filename == "octez-baker" then
				key = "baker"
			elseif filename == "octez-accuser" then
				key = "accuser"
			end

			if key then
				local url = "https://octez.tezos.com/releases/" ..
					target_version .. "/binaries/" .. bin_arch .. "/" .. filename
				new_platform_sources[key] = {
					url = url,
					hash = hash
				}
			end
		end
	end
	new_sources_map[platform] = new_platform_sources
end

-- Update macOS sources
local macos_platforms = { "darwin-arm64", "darwin-x86_64" }
-- Fetch GitHub releases
print("Fetching macOS releases from GitHub...")
local gh_response = net.download_string("https://api.github.com/repos/tez-capital/tezos-macos-pipeline/releases")
local gh_releases = {}
if #gh_response > 0 then
	gh_releases = hjson.parse(gh_response)
end

local found_tag = nil
for _, release in ipairs(gh_releases) do
	-- Use plain string comparison to avoid Lua pattern magic character issues (., -)
	if release.tag_name:sub(1, #target_version + 1) == target_version .. "-" then
		found_tag = release.tag_name
		break
	end
end

if not found_tag then
	print("Warning: No matching macOS release found for " .. target_version)
else
	print("Found macOS release: " .. found_tag)
end

local found_release = nil
for _, release in ipairs(gh_releases) do
	-- Use plain string comparison to avoid Lua pattern magic character issues (., -)
	if release.tag_name:sub(1, #target_version + 2) == target_version .. "-2" then
		found_release = release
		break
	end
end

if not found_release then
	print("Warning: No matching macOS release found for " .. target_version)
else
	print("Found macOS release: " .. found_release.tag_name)
end

for platform, sources in pairs(current_sources) do
	if platform:match("^darwin") then
		print("Updating " .. platform .. "...")
		local new_platform_sources = {}

		-- Copy prism
		if sources.prism then
			new_platform_sources.prism = sources.prism
		end

		if found_release then
			local asset_ids = {
				node = "octez-node",
				client = "octez-client",
				baker = "octez-baker",
				accuser = "octez-accuser"
			}

			for key, asset_name in pairs(asset_ids) do
				local found_asset = nil
				if found_release.assets then
					for _, asset in ipairs(found_release.assets) do
						if asset.name == asset_name then
							found_asset = asset
							break
						end
					end
				end

				if found_asset then
					local hash = nil
					if found_asset.digest then
						hash = found_asset.digest:match("sha256:(%x+)")
					end

					new_platform_sources[key] = {
						url = found_asset.browser_download_url,
						hash = hash
					}
				else
					print("Warning: Asset " .. asset_name .. " not found in release")
				end
			end
		else
			print("Skipping macOS update due to missing tag")
			for k, v in pairs(sources) do
				if k ~= "prism" then
					-- Preserve old
					new_platform_sources[k] = v
				end
			end
		end
		new_sources_map[platform] = new_platform_sources
	end
end


-- Merge into final structure
for k, v in pairs(current_sources) do
	if not new_sources_map[k] then
		new_sources_map[k] = v
	end
end

local new_content = "// SOURCE: https://octez.tezos.com/releases \n" ..
	"// macOS SOURCE: https://github.com/tez-capital/tezos-macos-pipeline/releases \n"
new_content = new_content .. hjson.stringify(new_sources_map, { separator = true, sort_keys = true })

fs.write_file("src/__xtz/sources.hjson", new_content)
