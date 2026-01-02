const std = @import("std");
const trait_module = @import("Trait.zig").impl;

pub const impl = struct {
    pub fn Limits(comptime T: type) type {
        const Tr = trait_module.Trait(T);

        return struct {
            pub const zero: T = switch (Tr.kind) {
                .Float => 0.0,
                else => 0,
            };

            pub const one: T = switch (Tr.kind) {
                .Float => 1.0,
                else => 1,
            };

            pub const min: T = switch (Tr.kind) {
                .Int => std.math.minInt(T),
                .UInt => 0,
                .Float => -std.math.inf(T),
                else => @compileError("no min"),
            };

            pub const max: T = switch (Tr.kind) {
                .Int => std.math.maxInt(T),
                .UInt => std.math.maxInt(T),
                .Float => std.math.inf(T),
                else => @compileError("no max"),
            };

            pub inline fn isZero(v: T) bool {
                return v == zero;
            }

            pub inline fn isMax(v: T) bool {
                return v == max;
            }

            pub inline fn isMin(v: T) bool {
                return v == min;
            }
        };
    }
};