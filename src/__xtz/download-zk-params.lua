local PARAMS_DIR = "data/.zcash-params"
local DOWNLOAD_URL = "https://github.com/tez-capital/zk-params/archive/refs/heads/main.zip"

local function _has_valid_zk_params()
    if not fs.exists(PARAMS_DIR) then
        return false
    end
    local _fileHashes = {
        ["sapling-output.params"] = "2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4",
        ["sapling-spend.params"] = "8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13",
        ["sprout-groth16.params"] = "b685d700c60328498fbde589c8c7c484c722b788b265b72af448a5bf0ee55b50"
    }

    for k, v in pairs(_fileHashes) do
        local _fPath = path.combine(PARAMS_DIR, k)
        local _, _hash = fs.safe_hash_file(_fPath, { hex = true })
        if _hash ~= v then
            return false
        end
    end
    return true
end

local function download_zk_params() 
    if _has_valid_zk_params() then
        return true
    end

    local _ok, _error = fs.safe_mkdirp(PARAMS_DIR)
    if not _ok then return _ok, _error end

    local _tmpFile = os.tmpname()
    log_trace("downloading params zip ...")
    local _ok, _error = net.safe_download_file(DOWNLOAD_URL, _tmpFile, {followRedirects = true, showDefaultProgress = true})
    if not _ok then return _ok, _error end
    log_trace("extracting params zip ...")
    local _ok, _error = zip.safe_extract(_tmpFile, PARAMS_DIR, { flattenRootDir = true })
    fs.safe_remove(_tmpFile)
    if not _ok then return _ok, _error end

    -- merge groth16
    local _grothFilePath = path.combine(PARAMS_DIR, "sprout-groth16.params")
    fs.safe_remove(_grothFilePath)
    local _grothFile, _error = io.open(_grothFilePath, "ab")
    if not _grothFile then return false, _error end

    for i = 0, 15 do
        local _partNumber = string.format(".%02d", i)
        local _partPath = _grothFilePath .. _partNumber
        log_trace("merging part " .. _partNumber .." of groth16...")
        local _ok, _error = fs.safe_copy_file(_partPath, _grothFile)
        fs.safe_remove(_partPath)
        if not _ok then
            fs.safe_remove(_grothFilePath)
            return _ok, _error
        end
    end
    if _has_valid_zk_params() then
        log_trace("params ready")
        return true
    else
        return false, "invalid params hashes"
    end
end

return download_zk_params