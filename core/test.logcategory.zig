const std = @import("std");
const log_category_module = @import("Logger/LogCategory.Logger.zig");

pub fn main() !void {
    //var allocator = std.heap.page_allocator;

    const cat1 = try log_category_module.impl.LogCategory.getOrCreate("foo.bar");

    std.debug.print("cat1 name: {s}\n", .{cat1.getName()});

    const cat2 = try log_category_module.impl.LogCategory.getOrCreate("foo.bar");
    std.debug.print("cat2 name: {s}\n", .{cat2.getName()});

    const cat3 = try log_category_module.impl.LogCategory.getOrCreate("baz.qux");
    std.debug.print("cat3 name: {s}\n", .{cat3.getName()});

    if (cat1.data.ptr == cat2.data.ptr) {
        std.debug.print("cat1 and cat2 are the same instance (as expected)\n", .{});
    } else {
        std.debug.print("ERROR: cat1 and cat2 should be the same instance!\n", .{});
    }

    if (cat1.data.ptr != cat3.data.ptr) {
        std.debug.print("cat1 and cat3 are different instances (as expected)\n", .{});
    } else {
        std.debug.print("ERROR: cat1 and cat3 should be different instances!\n", .{});
    }
}