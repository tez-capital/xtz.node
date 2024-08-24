local keys = { "baker" }

keys = util.merge_arrays(keys, am.app.get_configuration("additional_key_aliases", {}))

--- load pkhs
--[[
[ { "name": "bob", "value": "tz1..." } ]
]]

local ok, pkhsFile = fs.safe_read_file("data/.tezos-client/public_key_hashs")
local pkhs = {}
if ok then
    local aliases = hjson.parse(pkhsFile)
    for _, alias in ipairs(aliases) do
        if table.includes(keys, alias.name) then
            table.insert(pkhs, alias.value)
        end
    end
end

for _, pkh in ipairs(pkhs) do
    print(pkh)
end
