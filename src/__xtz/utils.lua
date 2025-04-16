local utils = {}

-- Converts URLs to "host:port" format as described:
-- should be used only for RPC_ADDR and REMOTE_SIGNER_ADDR
-- "http://127.0.0.1/"        -> "127.0.0.1:80"
-- "https://127.0.0.1/"       -> "127.0.0.1:443"
-- "http://127.0.0.1:2090/"   -> "127.0.0.1:2090"
-- "127.0.0.1:90"             -> "127.0.0.1:90"
---@param input string
---@return string
function utils.extract_host_and_port(input, default_port)
    if not input or input == "" then
        return input
    end
    -- Try to match URLs starting with "http://" or "https://"
    local protocol, host, port = string.match(input, "^(https?)://([^/:]+):?(%d*)")
    if protocol then
        -- Assign the default port when no port is provided
        if port == "" then
            if protocol == "http" then
                port = "80"
            elseif protocol == "https" then
                port = "443"
            end
        end
        return host .. ":" .. port
    else
        -- For strings without http(s)://, try matching a host:port pattern
        local host_only, port_only = string.match(input, "^([^/:]+):(%d+)")
        if host_only and port_only then
            return host_only .. ":" .. port_only
        else
            -- If the input doesn't match expected patterns, return it unchanged.
            local port_suffix = default_port and ":" .. default_port or ""
            return input .. port_suffix
        end
    end
end

return utils