const core_module = @import("Core.String.zig").impl;

pub const impl = struct {
    pub inline fn String(comptime CharT: type) type {
        return struct {

        };
    }
};