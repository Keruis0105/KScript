pub const impl = struct {
    pub fn BitOps(comptime Tr: type) type {
        return struct {
            pub const value_t = Tr.value_t;
            pub const bit_t = Tr.bit_t;

            pub inline fn not(value: value_t) value_t {
                return ~value;
            }

            pub inline fn set(value: value_t, bit: bit_t) value_t {
                return value | (@as(value_t, 1) << bit);
            }

            pub inline fn clear(value: value_t, bit: bit_t) value_t {
                return value & ~(@as(value_t, 1) << bit);
            }

            pub inline fn toggle(value: value_t, bit: bit_t) value_t {
                return value ^ (@as(value_t, 1) << bit);
            }

            pub inline fn isSet(value: value_t, bit: bit_t) bool {
                return (value & (@as(value_t, 1) << bit)) != 0;
            }

            pub inline fn assign(value: value_t, bit: bit_t, on: bool) value_t {
                const mask = @as(value_t, 1) << bit;
                return if (on)
                    value | mask
                else
                    value & ~mask;
            }
        };
    }
};