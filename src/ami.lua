return {
    title = "XTZ node",
    commands = {
        info = {
            description = "ami 'info' sub command",
            summary = "Prints runtime info and status of the app",
            action = "__xtz/info.lua",
            options = {
                ["timeout"] = {
                    aliases = { "t" },
                    description = 'Sets time to wait for info collections',
                    type = "number"
                },
                ["services"] = {
                    description = "Prints info about services",
                    type = "boolean"
                },
                ["voting"] = {
                    description = "Prints info about voting period",
                    type = "boolean"
                },
                ["chain"] = {
                    description = "Prints info about chain state",
                    type = "boolean"
                },
                ["simple"] = {
                    aliases = "s",
                    description = "Prints simplified info",
                    type = "boolean"
                }
            },
            contextFailExitCode = EXIT_APP_INFO_ERROR
        },
        setup = {
            options = {
                configure = {
                    description = "Configures application, renders templates and installs services"
                }
            },
            action = function(_options, _, _, _)
                local _noOptions = #table.keys(_options) == 0
                if _noOptions or _options.environment then
                    am.app.prepare()
                end

                if _noOptions or not _options["no-validate"] then
                    am.execute("validate", { "--platform" })
                end

                if _noOptions or _options.app then
                    am.execute_extension("__xtz/download-binaries.lua", { contextFailExitCode = EXIT_SETUP_ERROR })
                end

                if _noOptions and not _options["no-validate"] then
                    am.execute("validate", { "--configuration" })
                end

                if _noOptions or _options.configure then
                    am.execute_extension('__xtz/create_user.lua', { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
                    am.app.render()
                    am.execute_extension("__xtz/configure.lua", { contextFailExitCode = EXIT_APP_CONFIGURE_ERROR })
                end
                log_success("XTZ node setup complete.")
            end
        },
        start = {
            description = "ami 'start' sub command",
            summary = "Starts the XTZ node",
            action = "__xtz/start.lua",
            contextFailExitCode = EXIT_APP_START_ERROR
        },
        stop = {
            description = "ami 'stop' sub command",
            summary = "Stops the XTZ node",
            action = "__xtz/stop.lua",
            contextFailExitCode = EXIT_APP_STOP_ERROR
        },
        validate = {
            description = "ami 'validate' sub command",
            summary = "Validates app configuration and platform support",
            action = function(_options, _, _, _cli)
                if _options.help then
                    show_cli_help(_cli)
                    return
                end
                -- //TODO: Validate platform
                ami_assert(proc.EPROC, "xtz node AMI requires extra api - eli.proc.extra", EXIT_MISSING_API)
                ami_assert(fs.EFS, "xtz node AMI requires extra api - eli.fs.extra", EXIT_MISSING_API)

                ami_assert(type(am.app.get("id")) == 'string', "id not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get_config()) == 'table', "configuration not found in app.h/json!",
                    EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get("user")) == 'string', "USER not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get_type()) == "table" or type(am.app.get_type()) == "string", "Invalid app type!"
                    , EXIT_INVALID_CONFIGURATION)
                log_success("XTZ node configuration validated.")
            end
        },
        bootstrap = {
            description = "ami 'bootstrap' sub command",
            summary = 'Bootstraps XTZ chain',
            action = '__xtz/bootstrap.lua',
            type = "raw",
            contextFailExitCode = EXIT_APP_START_ERROR
        },
        client = {
            description = "ami 'signer' sub command",
            summary = "Passes any passed arguments directly to tezos-client.",
            index = 8,
            type = "external",
            exec = "bin/client",
            environment = {
                HOME = path.combine(os.cwd(), "data")
            },
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        },
        node = {
            description = "ami 'node' sub command",
            summary = "Passes any passed arguments directly to tezos-node.",
            index = 9,
            type = "external",
            exec = "bin/node",
            environment = {
                HOME = path.combine(os.cwd(), "data")
            },
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        },
        ["import-key"] = {
            description = "ami 'import-key' sub command",
            summary = "Attempts to import ledger key (Assumes only one ledger is connected).",
            index = 10,
            action = "__xtz/import_key.lua",
            type = "raw",
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        },
        log = {
            description = "ami 'log' sub command",
            summary = 'Prints logs from services.',
            options = {
                ["follow"] = {
                    aliases = { "f" },
                    description = "Keeps printing the log continuously.",
                    type = "boolean"
                },
                ["end"] = {
                    aliases = { "e" },
                    description = "Jumps to the end of the log.",
                    type = "boolean"
                }
            },
            type = "no-command",
            action = '__xtz/log.lua',
            contextFailExitCode = EXIT_APP_INTERNAL_ERROR
        },
        about = {
            description = "ami 'about' sub command",
            summary = "Prints information about application",
            action = function(_options, _, _, _)
                local _ok, _aboutFile = fs.safe_read_file("__xtz/about.hjson")
                ami_assert(_ok, "Failed to read about file!", EXIT_APP_ABOUT_ERROR)

                local _ok, _about = hjson.safe_parse(_aboutFile)
                _about["App Type"] = am.app.get({ "type", "id" }, am.app.get("type"))
                ami_assert(_ok, "Failed to parse about file!", EXIT_APP_ABOUT_ERROR)
                if am.options.OUTPUT_FORMAT == "json" then
                    print(hjson.stringify_to_json(_about, { indent = false, skipkeys = true }))
                else
                    print(hjson.stringify(_about))
                end
            end
        },
        remove = {
            index = 7,
            options = {
                chain = {
                    description = "Remove chain data only."
                }
            },
            action = function(_options, _, _, _)
                if _options.chain then
                    am.execute_extension("__xtz/remove-chain.lua", { contextFailExitCode = EXIT_RM_ERROR })
                end
                if _options.all then
                    am.execute_extension("__xtz/remove-all.lua", { contextFailExitCode = EXIT_RM_ERROR })
                    am.app.remove()
                    log_success("Application removed.")
                end
                if #table.keys(_options) == 0 then
                    am.app.remove_data()
                    log_success("Application data removed.")
                end
                return
            end
        },
    }
}
