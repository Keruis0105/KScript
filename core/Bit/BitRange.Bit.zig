pub const impl = struct {
    pub fn BitRange(comptime Tr: type) type {
        return struct {
            pub const value_t = Tr.value_t;
            pub const bit_t = Tr.bit_t;

            const Mask = @import("BitMask.Bit.zig").impl.BitMask(Tr);

            pub inline fn extract(value: value_t, lo: bit_t, hi: bit_t) value_t {
                const mask = Mask.range(lo, hi);
                return (value & mask) >> lo;
            }

            pub inline fn insert(value: value_t, lo: bit_t, hi: bit_t, bits: value_t) value_t {
                const mask = Mask.range(lo, hi);
                const cleared = value & ~mask;
                const shifted = (bits << lo) & mask;
                return cleared | shifted;
            }

            pub inline fn replace(value: value_t, lo: bit_t, hi: bit_t, new_bits: value_t) value_t {
                return insert(value, lo, hi, new_bits);
            }

            pub inline fn clear(value: value_t, lo: bit_t, hi: bit_t) value_t {
                const mask = Mask.range(lo, hi);
                return value & ~mask;
            }
        };
    }
};