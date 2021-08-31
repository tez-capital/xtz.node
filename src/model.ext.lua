local _dataDir = path.combine(os.cwd(), "data")

am.app.set_model(
    {
        RPC_ADDR = am.app.get_configuration("RPC_ADDR", "127.0.0.1"),
		SERVICE_CONFIGURATION = util.merge_tables(
            {
                TimeoutStopSec = 300,
            },
            type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and am.app.get_configuration("SERVICE_CONFIGURATION") or {},
            true
        )
    },
    { merge = true, overwrite = true }
)
