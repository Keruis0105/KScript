const std = @import("std");
const String = @import("Mod.Core.zig").String.string;
const dir = @import("FileSystem/DirectoryOps.FileSystem.zig").impl.DirectoryOps;
const file_system_error = @import("FileSystem/Error.FileSystem.zig").impl.FileSystemError;

pub fn main() !void {
    const s1 = try String.init_str("./core");
    var t1 = try dir.init(s1);
    const d1 = try t1.scan();
    const ie1 = try d1.getInfo();
    if (d1.err) |e| {
        std.debug.print("Scan error: {}\n", .{e});
    } else {
        std.debug.print("Directory name: {s}\n", .{ie1.?.full_path.as_slice()});
        std.debug.print("Depth: {d}\n", .{ie1.?.depth});
        std.debug.print("File: {d}\n", .{ie1.?.file_count});
    }

    std.debug.print("{}", .{t1.path_type});

    
}