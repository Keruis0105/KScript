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

            storage: box_t.Storage = box_t.initEmpty(),

            pub fn init() @This() {
                return .{};
            }

            pub fn init_c(alloc: std.mem.Allocator, c: char_t) !@This() {
                var self: @This() = .{};
                self.storage.as_cache.data_[box_t.max_cache_size] = 1;
                try self.assign_init_c(alloc, c);
                return self;
            }

            pub fn init_str(alloc: std.mem.Allocator, str: const_pointer_t) !@This() {
                var self: @This() = .{};
                const str_length = @import("Backend/strlen.zig").Backend.strlen(
                    char_t, str
                );
                if (str_length >= box_t.max_cache_size) {
                    self.storage.as_large.setCapacity(0, .{
                        .storage = .Large,
                        .ownership = .Owning
                    });
                }
                try self.assign_init_str(alloc, str, str_length);
                return self;
            }

            pub fn pointer(self: *@This()) pointer_t {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.pointer(),
                    .Heap, .Shared => 
                        return self.storage.as_large.pointer()
                }
            }

            pub fn size(self: *@This()) usize {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.size(),
                    .Heap, .Shared => 
                        return self.storage.as_large.size()
                }
            }

            fn assign_init_c(self: *@This(), alloc: std.mem.Allocator, c: char_t) !void {
                switch (box_t.modeTag(&self.storage)) {
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
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        const large_size: usize = large.size();
                        var alloc_slice: []char_t = undefined;
                        if (large.capacity() < large_size) {
                            const alloc_size: usize = large_size + (large_size / 2);
                            alloc_slice = try alloc.alloc(char_t, alloc_size);
                            self.storage.as_large.setCapacity(alloc_size, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                        }
                        @import("Backend/strset.zig").Backend.strset(
                            char_t,
                            alloc_slice.ptr,
                            c,
                            large_size
                        );
                        large.data_ = alloc_slice.ptr;
                        large.pointer()[large_size] = 0;
                    },
                    .Shared => {
                        var shared: *box_data_t = &self.storage.as_large;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            self.storage.as_large.setCapacity(0, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            self.storage.as_large.size_ = rc.size();
                            try self.assign_init_c(alloc, c);
                            _ = box_t.RcHeader.release(true, rc);
                        }
                    }
                }
            }

           fn assign_init_str(self: *@This(), alloc: std.mem.Allocator, str: const_pointer_t, length: usize) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => {
                        var cache: *cache_buffer_t = &self.storage.as_cache;
                        const str_size = length;
                        @import("Backend/strcpy.zig").Backend.strcpy(
                            char_t,
                            cache.pointer(),
                            str,
                            str_size
                        );
                        self.storage.as_cache.data_[box_t.max_cache_size] = @intCast(str_size);
                    },
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        const str_size = length;
                        const alloc_size: usize = str_size + (str_size / 2);
                        var alloc_slice = try alloc.alloc(char_t, alloc_size);
                        self.storage.as_large.setCapacity(alloc_size, category_module.Mode{
                            .storage = .Large,
                            .ownership = .Owning
                        });
                        @import("Backend/strcpy.zig").Backend.strcpy(
                            char_t,
                            alloc_slice.ptr,
                            str,
                            str_size
                        );
                        large.data_ = alloc_slice.ptr;
                        large.size_ = str_size;
                        large.pointer()[str_size] = 0;
                    },
                    .Shared => {
                        var shared: *box_data_t = &self.storage.as_large;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            self.storage.as_large.setCapacity(0, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            try self.assign_init_str(alloc, str, length);
                            _ = box_t.RcHeader.release(true, rc);
                        }
                    }
                }
            }
        };
    }
};