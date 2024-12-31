local hjson = require "hjson"

local sources_raw = fs.read_file("src/__xtz/sources.hjson")
local sources = hjson.parse(sources_raw)

local source_urls = {}
local source_ids = {}

for _, platform_sources in pairs(sources) do
	for _, source_url in pairs(platform_sources) do
		if table.includes(source_urls, source_url) then
			error("Duplicate source url: " .. source_url)
		end
		table.insert(source_urls, source_url)

		-- https://gitlab.com/tezos/tezos/-/package_files/130339715/download
		-- extract id from url
		local source_id = source_url:match("package_files/(%d+)/download")
		if not source_id then
			error("Invalid source url: " .. source_url)
		end
		if table.includes(source_ids, source_id) then
			error("Duplicate source id: " .. source_id)
		end
		table.insert(source_ids, source_id)
	end
end

if #source_urls < 4 then
	error("Not enough source urls found")
end
print("Validated " .. #source_urls .. " source urls")
