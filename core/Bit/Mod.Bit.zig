const bit_ops_module = @import("BitOps.Bit.zig").impl;
const bit_mask_module = @import("BitMask.Bit.zig").impl;
const bit_shift_module = @import("BitShift.Bit.zig").impl;
const bit_range_module = @import("BitRange.Bit.zig").impl;
const bit_utils_module = @import("BitUtils.Bit.zig").impl;
const trait_module = @import("Trait.Bit.zig").impl;

pub const mod = struct {
    pub fn Bit(comptime Ty: type) type {
        const trait = trait_module.Trait(Ty);
        return struct {
            pub const ops = bit_ops_module.BitOps(trait);
            pub const mask = bit_mask_module.BitMask(trait);
            pub const shift = bit_shift_module.BitShift(trait);
            pub const range = bit_range_module.BitRange(trait);
            pub const utils = bit_utils_module.BitUtils(trait);
        };
    }
};