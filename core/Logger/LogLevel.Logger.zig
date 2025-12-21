pub const impl = struct {
    pub const LogLevelEnumType = u32;
    pub const LogLevel = enum(LogLevelEnumType) {
        // 未初始化 / 无日志
        UNINITIALIZED = 0x0,
        NONE        = 0x00989680,   // 10_000_000
        MIN_LEVEL   = 0x00989680,   // 10_000_000

        // Debug levels
        DBG9 = 0x05F5E100, DBG8 = 0x06871900, DBG7 = 0x0720C600, DBG6 = 0x07C1A300,
        DBG5 = 0x08872A00, DBG4 = 0x08F0E400, DBG3 = 0x09896800, DBG2 = 0x0A2C6C00,
        DBG1 = 0x0AB1B800, DBG0 = 0x0B70A600,
        DBG  = 0x0BEBC200, // 默认DBG等级 (200_000_000)

        // Info levels
        INFO9 = 0x1DCD6500, INFO8 = 0x1E6E1C00, INFO7 = 0x1F640400, INFO6 = 0x1FDEB400,
        INFO5 = 0x204F6800, INFO4 = 0x20F8C400, INFO3 = 0x219E6800, INFO2 = 0x21F8B400,
        INFO1 = 0x22AE3000, INFO0 = 0x23489C00,
        INFO  = 0x23A6800, // 默认INFO等级 (600_000_000)

        // Warnings
        WARN    = 0x29FDC000, // 700_000_000
        WARNING = 0x29FDC000, // alias

        // Errors
        ERR = 0x2FAF0800, // 800_000_000

        // Critical
        CRITICAL = 0x35F5E100, // 900_000_000

        // Fatal
        DFATAL = 0x7FFFFFEE, // debug致命错误
        FATAL  = 0x7FFFFFFF, // release致命错误

        MAX_LEVEL = 0xFFFFFFFF, // uint32 最大值
    };

    pub const default_log_level: LogLevel = .INFO;
};