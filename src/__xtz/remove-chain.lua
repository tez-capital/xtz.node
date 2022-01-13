local _keep = {
	"config.json",
	"identity.json",
	"peers.json"
}

local _ok, _entries = fs.safe_read_dir("data/.tezos-node", { returnFullPaths = true })
ami_assert(_ok, "Failed to remove chain files - " .. tostring(_entries))
for _, entry in ipairs(_entries or {}) do
	local _matched = false
	for _, keep in ipairs(_keep) do
		_matched = _matched or entry:match(keep.."$")
	end
	if not _matched then
		fs.safe_remove(entry, { recurse = true, followLinks = true })
	end
end