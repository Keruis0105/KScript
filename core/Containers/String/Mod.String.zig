const character_type_module = @import("CharacterType.String.zig").impl;
const trait_module = @import("Trait.String.zig").impl;
const memory_module = @import("../../Memory/Mod.Memory.zig");

pub const mod = struct {
    pub const string = @import("Core.String.zig").impl.Core(trait_module.Trait(.char), memory_module.Allocator.Allocator(character_type_module.CharTypeOf(.char)));
    pub const wstring = @import("Core.String.zig").impl.Core(trait_module.Trait(.wchar), memory_module.Allocator.Allocator(character_type_module.CharTypeOf(.wchar)));
    pub const u8string = @import("Core.String.zig").impl.Core(trait_module.Trait(.u8char), memory_module.Allocator.Allocator(character_type_module.CharTypeOf(.u8char)));
    pub const u16string = @import("Core.String.zig").impl.Core(trait_module.Trait(.u16char), memory_module.Allocator.Allocator(character_type_module.CharTypeOf(.u16char)));
    pub const u32string = @import("Core.String.zig").impl.Core(trait_module.Trait(.u32char), memory_module.Allocator.Allocator(character_type_module.CharTypeOf(.u32char)));
};