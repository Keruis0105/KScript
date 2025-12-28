pub const impl = struct {
    pub fn BitShift(comptime Tr: type) type {
        return struct {
            pub const value_t = Tr.value_t;
            pub const bit_t = Tr.bit_t;
            pub const bit_count = Tr.bit_count;
            pub const is_signed = Tr.is_signed;

            pub inline fn shl(value: value_t, amount: bit_t) value_t {
                return value << amount;
            }

            pub inline fn shr(value: value_t, amount: bit_t) value_t {
                return value >> amount;
            }

            pub inline fn sar(value: value_t, amount: bit_t) value_t {
                if (is_signed) {
                    return value >> amount;
                } else {
                    return value >> amount;
                }
            }

            pub inline fn rol(value: value_t, amount: bit_t) value_t {
                const m = amount % @as(value_t, bit_count);
                return (value << m) | (value >> (bit_count - m));
            }

            pub inline fn ror(value: value_t, amount: bit_t) value_t {
                const m = amount % @as(value_t, bit_count);
                return (value >> m) | (value << (bit_count - m));
            }
        };
    }
};