local keep = {
	"config.json",
	"identity.json",
	"peers.json"
}

local ok, entries = fs.safe_read_dir("data/.tezos-node", { return_full_paths = true })
ami_assert(ok, "Failed to remove chain files - " .. tostring(entries))
for _, entry in ipairs(entries or {}) do
	local matched = false
	for _, keep in ipairs(keep) do
		matched = matched or entry:match(keep.."$")
	end
	if not matched then
		fs.safe_remove(entry, { recurse = true, follow_links = true })
	end
end