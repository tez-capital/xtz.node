local hjson = require "hjson"

local sources_raw = fs.read_file("src/__xtz/sources.hjson")
local sources = hjson.parse(sources_raw)

local source_urls = {}
local source_ids = {}

for platform, platform_sources in pairs(sources) do
	for id, source_value in pairs(platform_sources) do
		if id == "prism" then -- below validation is just for octez binaries
			goto continue
		end

		local source_url
		local source_hash

		if type(source_value) == "table" then
			source_url = source_value.url
			source_hash = source_value.sha256

			if not source_url then
				error("Missing source url for " .. id)
			end
			-- Enforce hash for linux
			if platform:match("^linux") and not source_hash then
				error("Missing source hash for " .. id .. " on " .. platform)
			end
		else
			source_url = source_value
		end

		if table.includes(source_urls, source_url) then
			error("Duplicate source url: " .. source_url)
		end
		table.insert(source_urls, source_url)

		-- Validate URL format and extract ID
		-- Old: https://gitlab.com/tezos/tezos/-/package_files/130339715/download
		-- New: https://octez.tezos.com/releases/octez-v24.0-rc2/binaries/x86_64/octez-node
		-- macOS: https://github.com/tez-capital/tezos-macos-pipeline/releases/download/...

		local source_id = source_url:match("package_files/(%d+)/download") or
			source_url:match("tez%-capital/tezos%-macos%-pipeline/releases/download/.*") or
			source_url:match("octez%.tezos%.com/releases/.*/binaries/(.+)$") -- matches arch/filename

		if not source_id then
			error("Invalid source url: " .. source_url)
		end
		if table.includes(source_ids, source_id) then
			error("Duplicate source id: " .. source_id)
		end
		table.insert(source_ids, source_id)
		::continue::
	end
end

if #source_urls < 4 then
	error("Not enough source urls found")
end
print("Validated " .. #source_urls .. " source urls")

-- validate version
local specs_rwa = fs.read_file("src/specs.json")
local specs = hjson.parse(specs_rwa)
local version, err = ver.parse(specs.version)
assert(version, "Failed to parse version: " .. (err or ""))
