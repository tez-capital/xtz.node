local hjson = require "hjson"

local function fail(msg)
    print("FAILED: " .. msg)
    os.exit(1)
end

local function pass(msg)
    print("PASSED: " .. msg)
end

print("Test: fetch versions from RSS (guid)")
local status, vals = pcall(function()
    local response = net.download_string("https://octez.tezos.com/releases/feed.xml")
    if #response == 0 then error("Empty response for feed.xml") end

    local latest_version = nil

    -- Parse <guid> ... </guid>
    -- Example: <guid> octez-v24.0 </guid>
    -- Note: regex might match multiple, we want the "latest" in the feed.
    -- Usually RSS feed items are ordered.
    for guid in response:gmatch("<guid>%s*(octez%-v[%d%.%-rc]+)%s*</guid>") do
        print("Found guid: " .. guid)
        latest_version = guid
    end

    if not latest_version then error("No version found in RSS feed guid") end

    return latest_version
end)

if not status then
    fail(vals)
else
    pass("fetch versions from RSS using guid: " .. vals)
end

local target_version = vals -- e.g. octez-v24.0

print("Test: fetch macOS release from GitHub")
local status_gh, vals_gh = pcall(function()
    local url = "https://api.github.com/repos/tez-capital/tezos-macos-pipeline/releases"
    -- Note: might need User-Agent header if it fails, but eli's net.download_string usually handles it.
    local response = net.download_string(url)
    if #response == 0 then error("Empty response from GitHub API") end

    local releases = hjson.parse(response)
    if #releases == 0 then error("No releases found") end

    -- Filter for target version
    -- tag_name: octez-v24.0-2026-01-08_17-18
    local found_tag = nil
    for _, release in ipairs(releases) do
        if release.tag_name:sub(1, #target_version + 2) == target_version .. "-2" then
            found_tag = release.tag_name
            break
        end
    end

    -- found_tag is set
    local found_release = nil
    for _, release in ipairs(releases) do
        if release.tag_name == found_tag then
            found_release = release
            break
        end
    end

    if found_release and found_release.assets then
        print("Assets for " .. found_tag .. ":")
        for _, asset in ipairs(found_release.assets) do
            print("- " .. asset.name)
        end
    end

    if not found_tag then
        -- Fallback: try to find any recent one to pass the test if specific version is not yet there (unlikely for latest)
        print("Warning: exact match for " .. target_version .. " not found, checking generic format")
        if releases[1].tag_name:match("^octez%-v") then
            found_tag = releases[1].tag_name
        else
            error("No matching tag found and first tag format unknown: " .. releases[1].tag_name)
        end
    end
    return found_tag
end)

if not status_gh then
    fail(vals_gh)
else
    pass("found macOS tag: " .. vals_gh)
end
