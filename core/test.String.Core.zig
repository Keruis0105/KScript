const std = @import("std");
const character_type = @import("String/CharacterType.String.zig").impl;
const trait = @import("String/Trait.String.zig").impl;
const core = @import("String/Core.String.zig").impl;

const String = @import("Mod.Core.zig").String;

pub fn main() !void {
    const str = "abcdefk3jgviseeft2cgfvkhol";
    var t1 = String.string.init_str(str);
    std.debug.print("{d}\n", .{t1.capacity()});
    _ = try t1.resize(50, 'p');
    std.debug.print("{d}\n", .{t1.capacity()});
    var t2 =  try String.string.init_copy(&t1);
    const slice = t2.data()[0..t2.size()];
    std.debug.print("{s}\n", .{slice});
    defer t1.deinit();
    defer t2.deinit();
}