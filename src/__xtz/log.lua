local options, _, args, _ = ...

local args_values = table.map(args, function(v) return v.arg end)
local services = require("__xtz.services")

local to_check = table.values(services.all_names)
if #args_values > 0 then
    to_check = {}
    for _, v in ipairs(args_values) do
        if type(services.all_names[v]) == "string" then
            table.insert(to_check, services.all_names[v])
        end
    end
end

if am.app.get_model("SYSTEM_DISTRO", "unknown") == "MacOS" then
    local log_dir = "/usr/local/var/log/"
    local follow = options.follow
    local seek_end = options["end"]
    local streams = {}

    -- Open all log files as non-blocking streams
    for _, v in ipairs(to_check) do
        local log_path = log_dir .. v .. ".log"
        local f = io.open_fstream(log_path, "r")
        if f then
            f:set_nonblocking(true)
            if seek_end then
                f:seek("end")
            end
            table.insert(streams, {name = v, f = f})
        end
    end

    while true do
        local any_read = false
        for _, s in ipairs(streams) do
            while true do
                local line = s.f:read("l")
                if not line then
                    break
                end
                any_read = true
                print("[" .. s.name .. "] " .. line)
            end
        end
        if not follow then
            break
        end
        if not any_read then
            os.sleep(10, "ms")
        end
    end
else
    local journalctl_args = { "journalctl" }
    if options.follow then table.insert(journalctl_args, "-f") end
    if options['end'] then table.insert(journalctl_args, "-e") end
    if options.since then
        table.insert(journalctl_args, "--since")
        table.insert(journalctl_args, '"' .. tostring(options.since) .. '"')
    end
    if options["until"] then
        table.insert(journalctl_args, "--until")
        table.insert(journalctl_args, '"' .. tostring(options["until"]) .. '"')
    end
    for _, v in ipairs(to_check) do
        table.insert(journalctl_args, "-u")
        table.insert(journalctl_args, v)
    end

    os.execute(string.join(" ", table.unpack(journalctl_args)))
end
