--[[
# PATHS:
./prism
    - keys
        - ca.crt
        - ca.key
        - signer.prism
        - node.prism (optional)
        - dal.prism (optional)
    - conf.d
        - node.hjson
        - dal.hjson
    config.hjson
]]
log_info "configuring PRISM..."

fs.mkdirp("prism/keys")
fs.mkdirp("prism/conf.d") -- not needed right now

fs.copy("__xtz/prism/assets", "prism", { overwrite = true })
