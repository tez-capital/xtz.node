local PARAMS_DIR = "data/.zcash-params"
local DOWNLOAD_URL = "https://github.com/tez-capital/zk-params/archive/refs/heads/main.zip"

local function has_valid_zk_params()
    if not fs.exists(PARAMS_DIR) then
        return false
    end
    local file_hashes = {
        ["sapling-output.params"] = "2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4",
        ["sapling-spend.params"] = "8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13",
        ["sprout-groth16.params"] = "b685d700c60328498fbde589c8c7c484c722b788b265b72af448a5bf0ee55b50"
    }

    for k, v in pairs(file_hashes) do
        local file_path = path.combine(PARAMS_DIR, k)
        local _, hash = fs.safe_hash_file(file_path, { hex = true, type = "sha256" })
        if hash ~= v then
            return false
        end
    end
    return true
end

local function download_zk_params() 
    if has_valid_zk_params() then
        return true
    end

    local ok, err = fs.safe_mkdirp(PARAMS_DIR)
    if not ok then return ok, err end

    local tmp_file_path = os.tmpname()
    log_trace("downloading params zip ...")
    local ok, err = net.safe_download_file(DOWNLOAD_URL, tmp_file_path, {follow_redirects = true, show_default_progress = true})
    if not ok then return ok, err end
    log_trace("extracting params zip ...")
    local ok, err = zip.safe_extract(tmp_file_path, PARAMS_DIR, { flatten_root_dir = true })
    fs.safe_remove(tmp_file_path)
    if not ok then return ok, err end

    -- merge groth16
    local groth_file_path = path.combine(PARAMS_DIR, "sprout-groth16.params")
    fs.safe_remove(groth_file_path)
    local groth_file, err = io.open(groth_file_path, "ab")
    if not groth_file then return false, err end

    for i = 0, 15 do
        local part_number = string.format(".%02d", i)
        local part_path = groth_file_path .. part_number
        log_trace("merging part " .. part_number .." of groth16...")
        local ok, err = fs.safe_copy_file(part_path, groth_file)
        fs.safe_remove(part_path)
        if not ok then
            fs.safe_remove(groth_file_path)
            return ok, err
        end
    end
    if has_valid_zk_params() then
        log_trace("params ready")
        return true
    else
        return false, "invalid params hashes"
    end
end

return download_zk_params