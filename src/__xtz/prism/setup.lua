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
-- fs.mkdirp("prism/conf.d") -- not needed right now

--- load and validate configuration
---
--- {
---     remote: <default_remote>,
---     listening_forwarders: {} # see prism docs
---     connecting_forwarders: {} # see prism docs
---     default_forwarder: {
---         signer: <true|false> # whether to provide access to signer for default_remote
---         node: <true|false> # whether default_remote provides access to the node
---     }
--- }
local PRISM_CONFIGURATION = am.app.get_configuration("PRISM")
ami_assert(PRISM_CONFIGURATION, "PRISM configuration must be provided")

local are_listening_forwarders_valid_type = type(PRISM_CONFIGURATION.listening_forwarders) == "nil" or
    type(PRISM_CONFIGURATION.listening_forwarders) == "table"
ami_assert(are_listening_forwarders_valid_type, "invalid listening_forwarders type")
local are_connecting_forwarders_valid_type = type(PRISM_CONFIGURATION.connecting_forwarders) == "nil" or
    type(PRISM_CONFIGURATION.connecting_forwarders) == "table"
ami_assert(are_connecting_forwarders_valid_type, "invalid connecting_forwarders type")

local prism_configuration = {
    variables = {
        default_listen_on = am.app.get_configuration({ "PRISM", "listen_on" }, "0.0.0.0:20080"),
        default_rpc_endpoint = am.app.get_model("RPC_ADDR", "127.0.0.1") .. ":8732",
    },
    listening_forwarders = PRISM_CONFIGURATION.listening_forwarders,
    connecting_forwarders = PRISM_CONFIGURATION.connecting_forwarders,
}

ami_assert(
type(PRISM_CONFIGURATION.default_forwarder) == "nil" or PRISM_CONFIGURATION.default_forwarder == true or
    type(PRISM_CONFIGURATION.default_forwarder) == "table",
    "invalid 'PRISM.default_forwarder' type")
if type(table.get(prism_configuration.connecting_forwarders, "default_forwarder", nil)) ~= "nil" and type(PRISM_CONFIGURATION.default_forwarder) ~= "nil" then
    ami_error("PRISM.default_forwarder collides with PRISM.connecting_forwarders")
end

if PRISM_CONFIGURATION.default_forwarder == true then
    local signer_addr = am.app.get_model("REMOTE_SIGNER_ADDR", "http://127.0.0.1:20090/")
    local signer_endpoint = signer_addr:match("://([^/]+)") or signer_addr
    ami_assert(signer_endpoint, "invalid REMOTE_SIGNER_ADDR format")

    local dal_addr = am.app.get_model("REMOTE_DAL_ADDR", "http://127.0.0.1:10732/")
    local dal_endpoint = dal_addr:match("://([^/]+)") or dal_addr
    ami_assert(dal_endpoint, "invalid REMOTE_SIGNER_ADDR format")

    PRISM_CONFIGURATION.default_forwarder = {
        signer = signer_endpoint,
        rpc = "${default_rpc_endpoint}",
        dal = dal_endpoint
    }
end

if type(PRISM_CONFIGURATION.default_forwarder) == "table" then
    local listening_forwarder = {
        listen_on = "${default_listen_on}",

        key_path = PRISM_CONFIGURATION.default_forwarder.key or "prism/keys/node.prism",

        client_forwarders = {
        }
    }

    local signer_endpoint = PRISM_CONFIGURATION.default_forwarder.signer
    local dal_endpoint = PRISM_CONFIGURATION.default_forwarder.dal
    ami_assert(signer_endpoint or dal_endpoint, "at least one of signer or dal must be provided")

    if signer_endpoint then
        listening_forwarder.client_forwarders["tezos-signer"] = {
            forward_to = PRISM_CONFIGURATION.default_forwarder.rpc,
            forward_from = PRISM_CONFIGURATION.default_forwarder.signer,
        }
    end

    --// TODO: edit below 2 lines to enable dal forwarding
    -- if dal_endpoint then
    if false then
        listening_forwarder.client_forwarders["tezos-dal"] = {
            forward_to = PRISM_CONFIGURATION.default_forwarder.rpc,
            forward_from = PRISM_CONFIGURATION.default_forwarder.dal,
        }
    end

    local listening_forwarders = prism_configuration.listening_forwarders or {}
    listening_forwarders.default = listening_forwarder
    prism_configuration.listening_forwarders = listening_forwarders
end

local prism_configuration_path = "prism/config.hjson"
local ok = fs.safe_write_file(prism_configuration_path, hjson.stringify(prism_configuration))
ami_assert(ok, "failed to write prism configuration")
