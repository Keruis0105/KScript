const std = @import("std");

const S = struct {
    a: i32,
    b: i32,
    c: i32,
};

// 生成复制函数，skip 为要单独赋值的字段
fn generateCopyFn(comptime T: type, comptime skip: []const []const u8) fn (src: T, result: *T) void {
    return inline fn (src: T, result: *T) void {
        const info = @typeInfo(T);
        switch (info) {
            .@"struct" => |struct_info| {
                // 遍历字段生成赋值语句
                for (struct_info.fields) |field| {
                    var skip_field = false;
                    for (skip) |s| {
                        if (std.mem.eql(u8, s, field.name)) skip_field = true;
                    }
                    if (!skip_field) {
                        // 运行时赋值，这里是合法的
                        @field(result.*, field.name) = @field(src, field.name);
                    }
                }
            },
            else => @compileError("T must be a struct"),
        }
    };
}

pub fn main() void {
    var old = S{ .a = 1, .b = 2, .c = 3 };
    var new: S = undefined;

    // 生成复制函数
    const copyFn = generateCopyFn(S, &[_][]const u8{"a"});
    copyFn(old, &new); // runtime 复制剩余字段

    // 手动赋值你想改的字段
    new.a = 10;

    std.debug.print("old: {d}, {d}, {d}\n", .{old.a, old.b, old.c});
    std.debug.print("new: {d}, {d}, {d}\n", .{new.a, new.b, new.c});
}