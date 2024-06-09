local hjson = require "hjson"

local sourcesHjson = fs.read_file("src/__xtz/sources.hjson")
local sources = hjson.parse(sourcesHjson)

local sourceUrls = {}
local sourceIds = {}

for _, platformSources in pairs(sources) do
	for _, sourceUrl in pairs(platformSources) do
		if table.includes(sourceUrls, sourceUrl) then
			error("Duplicate source url: " .. sourceUrl)
		end
		table.insert(sourceUrls, sourceUrl)

		-- https://gitlab.com/tezos/tezos/-/package_files/130339715/download
		-- extract id from url
		local sourceId = sourceUrl:match("package_files/(%d+)/download")
		if not sourceId then
			error("Invalid source url: " .. sourceUrl)
		end
		if table.includes(sourceIds, sourceId) then
			error("Duplicate source id: " .. sourceId)
		end
		table.insert(sourceIds, sourceId)
	end
end

if #sourceUrls < 4 then
	error("Not enough source urls found")
end
print("Validated " .. #sourceUrls .. " source urls")
