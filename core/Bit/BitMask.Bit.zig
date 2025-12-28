pub const impl = struct {
    pub fn BitMask(comptime Tr: type) type {
        return struct {
            pub const value_t = Tr.value_t;
            pub const bit_t = Tr.bit_t;
            pub const bit_count = Tr.bit_count;

            pub inline fn bit(i: bit_t) value_t {
                return @as(value_t, 1) << i;
            }

            pub inline fn range(lo: bit_t, hi: bit_t) value_t {
                const width = hi - lo;
                const mask = (@as(value_t, 1) << width) - 1;
                return mask << lo;
            }

            pub inline fn low(n: bit_t) value_t {
                if (n == bit_count)
                    return ~(@as(value_t, 0));
                return (@as(value_t, 1) << n) - 1;
            }

            pub inline fn high(n: bit_t) value_t {
                const shift = bit_count - @as(@TypeOf(bit_count), n);
                return low(n) << shift;
            }

            pub inline fn except(lo: bit_t, hi: bit_t) value_t {
                return ~range(lo, hi);
            }
        };
    }
};