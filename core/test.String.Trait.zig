const std = @import("std");
const character_type = @import("String/CharacterType.String.zig").impl;
const trait = @import("String/Trait.String.zig").impl;
const core = @import("String/Core.String.zig").impl;

fn benchmarkOne(
    comptime id: character_type.CharTypeId,
    iterations: usize,
) void {
    const T = trait.Trait(id);
    const Ty = T.char_t;

    var buf1: [1024]Ty = undefined;
    var buf2: [1024]Ty = undefined;

    for (0..1023) |i| {
        buf1[i] = @as(Ty, 'a');
        buf2[i] = @as(Ty, 'a');
    }
    buf1[1023] = 0;
    buf2[1023] = 0;

    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        if (!T.compare_str(&buf1, &buf2, T.length(&buf1))) {
            @panic("unexpected compare failure");
        }
    }

    const elapsed_ns = timer.read();

    std.debug.print(
        \\CharType = {s}
        \\  iterations = {}
        \\  total time = {} ns
        \\  avg time   = {} ns/op
        \\
    ,
        .{
            @tagName(id),
            iterations,
            elapsed_ns,
            elapsed_ns / iterations,
        },
    );
}

pub fn main() void {
    const iterations: usize = 10_000_000;

    benchmarkOne(.u16char, iterations);
}