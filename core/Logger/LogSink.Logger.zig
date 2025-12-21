pub const impl = struct {
    pub const LogSinkType = enum {
        Console,
        File,
        Buffer,
        Network
    };

    pub const default_log_sink: LogSinkType = .Console;
};