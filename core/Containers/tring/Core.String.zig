const std = @import("std");
const category_module = @import("Category.String.zig").impl;
const box_module = @import("Box.String.zig").impl;

pub const impl = struct {
    pub fn Core(comptime Tr: type) type {
        return struct {
            pub const string_trait = Tr;
            const type_size: usize = string_trait.type_size;
            pub const char_t = string_trait.char_t;
            pub const pointer_t = string_trait.pointer_t;
            pub const const_pointer_t = string_trait.const_pointer_t;

            const box_t = box_module.Box(Tr);
            const box_data_t = box_t.box_data_t;
            const cache_buffer_t = box_t.cache_buffer_t;

            storage: box_t.Storage = .{},

            pub fn init_c(alloc: std.mem.Allocator, c: char_t) @This() {
                var self = .{};
                self.as_cache.data_[box_t.max_cache_size] = 1;
                self.assign_init_c(alloc, c);
                return self;
            }

            pub fn pointer(self: *@This()) pointer_t {
                switch (box_t.mode(self.storage)) {
                    .Inline => return self.as_cache.pointer(),
                    .View, .Large, .Shared => 
                        return self.as_large.pointer()
                }
            }

            fn assign_init_c(self: *@This(), alloc: std.mem.Allocator, c: char_t) !void {
                switch (box_t.modeTag(self.storage)) {
                    .Inline => {
                        var cache: *cache_buffer_t = &self.storage.as_cache;
                        const cache_size = cache.size();
                        @import("Backend/strset.zig").Backend.strset(
                            char_t,
                            cache.pointer(),
                            c,
                            cache_size
                        );
                    },
                    .View => {

                    },
                    .Large => {
                        var large: *box_data_t = &self.storage.as_large;
                        const large_size = large.size();
                        const alloc_size = large_size * 1.5;
                        var alloc_slice = try alloc.alloc(char_t, alloc_size);
                        self.storage.as_large.setCapacity(alloc_size, category_module.Mode{
                            .storage = .Large,
                            .ownership = .Owning
                        });
                        @import("Backend/strset.zig").Backend.strset(
                            char_t,
                            alloc_slice.ptr,
                            c,
                            large_size
                        );
                        large.data_ = alloc_slice.ptr;
                        large.pointer()[large_size] = char_t(0);
                    },
                    .Shared => {
                        var shared: *box_data_t = &self.storage.as_large;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, rc.refcount_, .seq_cst) > 1) {
                            const shared_size = rc.size();
                            const alloc_size = shared_size * 1.5;
                            var alloc_slice = try alloc.alloc(char_t, alloc_size);
                            self.storage.as_large.setCapacity(alloc_size, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            @import("Backend/strset.zig").Backend.strset(
                                char_t,
                                alloc_slice.ptr,
                                c,
                                shared_size
                            );
                            shared.data_ = alloc_slice.ptr;
                            shared.pointer()[shared_size] = char_t(0);
                            box_t.RcHeader.release(true, rc);
                        }
                    }
                }
            }
        };
    }
};