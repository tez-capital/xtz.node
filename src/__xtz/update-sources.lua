-- SOURCE: https://gitlab.com/tezos/tezos/-/releases
-- eli src/__xtz/update-sources.lua https://gitlab.com/tezos/tezos/-/packages/25835249 PsParisC

local hjson = require "hjson"
local args = table.pack(...)
if #args < 2 then
	print("Usage: update-sources <source-url> [protocols]")
	return
end

local source = args[1]
local protocol = args[2]
local protocol_next
if #args > 2 then
	protocol_next = args[3]
end

--- extract package id from url source - https://gitlab.com/tezos/tezos/-/packages/25835249
local package_id = source:match("packages/(%d+)")
if not package_id then
	print("Invalid source url")
	return
end

local response = net.download_string("https://gitlab.com/api/v4/projects/3836952/packages/" ..
	package_id .. "/package_files?per_page=100")
local files = hjson.parse(response)

local current_sources = hjson.parse(fs.read_file("src/__xtz/sources.hjson"))
for platform, sources in pairs(current_sources) do
	local new_sources = {}
	-- extract arch from linux-x86_64
	local arch = platform:match("linux%-(.*)")
	for source_id, source_url in pairs(sources) do
		if source_id == "prism" then
			new_sources[source_id] = source_url
			goto CONTINUE
		end

		-- build asset id => <arch>-octez-<source_id>
		local asset_ids = { [source_id] = arch .. "-octez-" .. source_id }
		if source_id:match("baker") or source_id:match("accuser") then
			asset_ids[source_id] = arch .. "-octez-" .. source_id .. "-" .. protocol
			if protocol_next then
				asset_ids[source_id .. "-next"] = arch .. "-octez-" .. source_id .. "-" .. protocol_next
			end
		end

		for asset_id, asset_name in pairs(asset_ids) do
			-- lookup file id
			for _, file in ipairs(files) do
				if file.file_name == asset_name then
					-- update source url
					-- https://gitlab.com/tezos/tezos/-/package_files/<id>/download
					new_sources[asset_id] = "https://gitlab.com/tezos/tezos/-/package_files/" .. file.id .. "/download"
					break
				end
			end
		end
		::CONTINUE::
	end
	current_sources[platform] = new_sources
end

local new_content = "// SOURCE: https://gitlab.com/tezos/tezos/-/releases\n"
new_content = new_content .. "// PROTOCOLS: " .. string.join(", ", protocol, protocol_next) .. "\n"
new_content = new_content .. hjson.stringify(current_sources, { separator = true })

fs.write_file("src/__xtz/sources.hjson", new_content)
