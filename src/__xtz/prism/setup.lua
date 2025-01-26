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
fs.mkdirp("prism/conf.d") -- not needed for signer

local signer_addr = am.app.get_configuration({ "PRISM", "signer" })
local needs_signer = signer_addr ~= nil

local dal_addr = am.app.get_configuration({ "PRISM", "dal" })
local needs_dal = dal_addr ~= nil

local prism_configuration = {
    listening_forwarders = {
        default = {
            listen_on = am.app.get_configuration({ "PRISM", "port" }, 20080),

            key_path = "prism/keys/node.key",

            client_forwarders = {
            }
        }
    }
}

if needs_signer then
    prism_configuration.listening_forwarders.default.client_forwarders["tezos-signer"] = {
        forward_to = am.app.get_mode("RPC_ADDR") + ":8732",
        forward_from = signer_addr,
    }
end

if needs_dal then
    prism_configuration.listening_forwarders.default.client_forwarders["tezos-dal"] = {
        forward_to = am.app.get_mode("RPC_ADDR") + ":8732",
        forward_from = dal_addr,
    }
end

local prism_configuration_path = "prism/config.hjson"
local ok = fs.safe_write_file(prism_configuration_path, hjson.stringify(prism_configuration))
ami_assert(ok, "failed to write prism configuration")
