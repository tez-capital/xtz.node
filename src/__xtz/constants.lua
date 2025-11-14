local node_binaries = { "client", "node" }
local baker_binaries = { "accuser", "baker" }
local vdf_binaries = { "baker" }

local wanted_binaries = util.clone(node_binaries)

local is_baker = am.app.get_configuration("NODE_TYPE") == "baker"
if is_baker then
    for _, v in ipairs(baker_binaries) do
        if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
            table.insert(wanted_binaries, v)
        end
    end
end

local is_vdf = am.app.get_configuration("NODE_TYPE") == "vdf"
if is_vdf then
    for _, v in ipairs(vdf_binaries) do
        if am.app.get_model({ "DOWNLOAD_URLS", v }, false) then
            table.insert(wanted_binaries, v)
        end
    end
end


local uses_prism = am.app.get_configuration("PRISM")
if uses_prism then
	table.insert(wanted_binaries, "prism")
end

return {
	wanted_binaries = wanted_binaries,
}