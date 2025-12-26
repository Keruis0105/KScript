// const std = @import("std");
// const string_module = @import("Containers/Mod.Containers.zig").String;
// const log_name_module = @import("Logger/LogName.Logger.zig").impl;
//
// pub fn main() !void {
//     const tests = [_][]const u8{
//         "foo/bar/baz",
//         "foo/bar/baz/",
//         "foo/bar/",
//         "foo/",
//         "",
//         "/foo/bar/baz",
//         "foo",
//     };
//
//     const expected = [_][]const u8{
//         "foo/bar",
//         "foo/bar",
//         "foo",
//         "",
//         "",
//         "/foo/bar",
//         "",
//     };
//
//     for (tests, 0..) |test_input, i| {
//         var parent = try log_name_module.LogName.getParent(test_input);
//         const parent_slice = parent.as_slice();
//
//         if (!std.mem.eql(u8, parent_slice, expected[i])) {
//             std.debug.print("ERROR: input '{s}' -> got '{s}', expected '{s}'\n",
//                 .{test_input, parent_slice, expected[i]});
//         } else {
//             std.debug.print("PASS: input '{s}' -> parent '{s}'\n", .{test_input, parent_slice});
//         }
//
//         parent.deinit();
//     }
// }

const std = @import("std");
const log_name_module = @import("Logger/LogName.Logger.zig").impl;

pub fn main() !void {
    const Test = struct {
        a: []const u8,
        b: []const u8,
        expected: i32,
    };

    const tests = [_]Test{
        Test{ .a = "foo.bar", .b = "foo.bar", .expected = 0 },
        Test{ .a = "foo.bar/", .b = "foo.bar", .expected = 0 },
        Test{ .a = "foo..bar", .b = "foo.bar", .expected = 0 },

        Test{ .a = "foo.bar", .b = "foo.baz", .expected = -1 },
        Test{ .a = "foo", .b = "foo.bar", .expected = -1 },
        Test{ .a = "", .b = "foo", .expected = -1 },

        Test{ .a = "foo.baz", .b = "foo.bar", .expected = 1 },
        Test{ .a = "foo.bar", .b = "foo", .expected = 1 },
        Test{ .a = "foo", .b = "", .expected = 1 },
    };

    for (tests) |t| {
        const result = log_name_module.LogName.cmp(t.a, t.b);
        const pass = (result == 0 and t.expected == 0)
            or (result < 0 and t.expected < 0)
            or (result > 0 and t.expected > 0);

        if (!pass) {
            std.debug.print("ERROR: cmp('{s}', '{s}') = {d}, expected {d}\n",
                .{t.a, t.b, result, t.expected});
        } else {
            std.debug.print("PASS: cmp('{s}', '{s}') = {d}\n", .{t.a, t.b, result});
        }
    }
}