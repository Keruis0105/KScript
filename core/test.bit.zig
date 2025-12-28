const std = @import("std");
const bit_mod = @import("Bit/Mod.Bit.zig").mod;

const bit = bit_mod.Bit(u32);

pub fn main() void {
    const debug = std.debug;

    var a: u32 = 0;
    a = bit.ops.set(a, 0);
    a = bit.ops.set(a, 3);
    a = bit.ops.toggle(a, 0);
    const is_set = bit.ops.isSet(a, 3);

    debug.print("Ops 测试:\n", .{});
    debug.print("a = ", .{});
    bit.utils.print(a);
    debug.print("第 3 位是否被设置: {}\n\n", .{is_set});

    const m1 = bit.mask.bit(2);
    const m2 = bit.mask.range(1,5);
    const m3 = bit.mask.low(4);
    const m4 = bit.mask.high(4);
    const m5 = bit.mask.except(1,3);

    debug.print("Mask 测试:\n", .{});
    debug.print("bit(2) = ", .{});
    bit.utils.print(m1);
    debug.print("range(1,5) = ", .{});
    bit.utils.print(m2);
    debug.print("low(4) = ", .{});
    bit.utils.print(m3);
    debug.print("high(4) = ", .{});
    bit.utils.print(m4);
    debug.print("except(1,3) = ", .{});
    bit.utils.print(m5);

    var s: u32 = 0b00001111;
    s = bit.shift.shl(s, 2);
    const sr = bit.shift.shr(s, 1);
    const rol = bit.shift.rol(0b10000001, 3);
    const ror = bit.shift.ror(0b10000001, 2);

    debug.print("\nShift 测试:\n", .{});
    debug.print("shl = ", .{});
    bit.utils.print(s);
    debug.print("shr = ", .{});
    bit.utils.print(sr);
    debug.print("rol = ", .{});
    bit.utils.print(rol);
    debug.print("ror = ", .{});
    bit.utils.print(ror);

    const r: u32 = 0b10111010;
    const ex = bit.range.extract(r, 2, 6);
    const ins = bit.range.insert(r, 2, 6, 0b0001);
    const clr = bit.range.clear(r, 2, 5);

    debug.print("\nRange 测试:\n", .{});
    debug.print("extract(2,6) = ", .{});
    bit.utils.print(ex);
    debug.print("insert(2,6,0b0001) = ", .{});
    bit.utils.print(ins);
    debug.print("clear(2,5) = ", .{});
    bit.utils.print(clr);
    debug.print("\n", .{});
}