local keep = {
	"config.json",
	"identity.json",
	"peers.json"
}

local entries, err = fs.read_dir("data/.tezos-node", { return_full_paths = true })
ami_assert(entries, "Failed to remove chain files - " .. tostring(err))
for _, entry in ipairs(entries or {}) do
	local matched = false
	for _, keep in ipairs(keep) do
		matched = matched or entry:match(keep.."$")
	end
	if not matched then
		fs.remove(entry, { recurse = true, follow_links = true })
	end
end