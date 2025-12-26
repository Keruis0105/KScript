const std = @import("std");
const log_category_module = @import("Logger/LogCategory.Logger.zig");

pub fn main() !void {
    const cat1 = try log_category_module.impl.LogCategory.getOrCreate("foo.bar");
    const cat2 = try log_category_module.impl.LogCategory.getOrCreate("foo.bar");
    const cat3 = try log_category_module.impl.LogCategory.getOrCreate("baz.qux");
    const cat4 = try log_category_module.impl.LogCategory.getOrCreate("foo.bar.baz");

    std.debug.print("cat1 name: {s}\n", .{cat1.getName()});
    std.debug.print("cat2 name: {s}\n", .{cat2.getName()});
    std.debug.print("cat3 name: {s}\n", .{cat3.getName()});
    std.debug.print("cat4 name: {s}\n", .{cat4.getName()});

    std.debug.assert(@intFromPtr(cat1.name_.cpointer()) == @intFromPtr(cat2.name_.cpointer()));
    std.debug.print("PASS: cat1 and cat2 are the same instance\n", .{});

    std.debug.assert(@intFromPtr(cat1.name_.cpointer()) != @intFromPtr(cat3.name_.cpointer()));
    std.debug.print("PASS: cat1 and cat3 are different instances\n", .{});

    std.debug.assert(@intFromPtr(cat2.name_.cpointer()) != @intFromPtr(cat4.name_.cpointer()));
    std.debug.print("PASS: cat2 and cat4 are different instances\n", .{});

    std.debug.assert(std.mem.eql(u8, cat1.getName(), "foo.bar"));
    std.debug.assert(std.mem.eql(u8, cat3.getName(), "baz.qux"));
    std.debug.assert(std.mem.eql(u8, cat4.getName(), "foo.bar.baz"));

    std.debug.print("All checks passed!\n", .{});
}