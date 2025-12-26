pub const impl = struct {
    pub const LogWriter = struct {
        writerMessage_: *const fn (self: *@This(), buffer: []const u8) void,
        flush_: *const fn (self: *@This()) void,
        ttyOutput_: *const fn (self: *const @This()) bool,

        pub fn writeMessage(self: *@This(), buffer: []const u8) void {
            self.writerMessage_(self, buffer);
        }

        pub fn writeMessageSync(self: *@This(), buffer: []const u8) void {
            self.writerMessage_(buffer);
            self.flush_();
        }
    };
};