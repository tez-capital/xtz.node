local hjson = require "hjson"

local sourcesHjson = fs.read_file("src/__xtz/sources.hjson")
local sources = hjson.parse(sourcesHjson)

local sourceUrls = {}

for _, platformSources in pairs(sources) do
	for _, sourceUrl in pairs(platformSources) do
		if table.includes(sourceUrls, sourceUrl) then
			error("Duplicate source url: " .. sourceUrl)
		end
		table.insert(sourceUrls, sourceUrl)
	end
end

if #sourceUrls < 4 then
	error("Not enough source urls found")
end
print("Validated " .. #sourceUrls .. " source urls")
