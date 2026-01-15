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
            const box_shared_t = box_t.box_shared_t;

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

            pub fn init_len(alloc: std.mem.Allocator, str: const_pointer_t, len: usize) !@This() {
                var self: @This() = .{};
                if (len >= box_t.max_cache_size) {
                    self.storage.as_large.setCapacity(0, .{
                        .storage = .Large,
                        .ownership = .Owning
                    });
                }
                try self.assign_init_str(alloc, str, len);
                return self;
            }

            pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => {},
                    .Heap => alloc.free(self.storage.as_large.pointer()),
                    .Shared => {
                        const rc = box_t.RcHeader.headerFromData(self.storage.as_shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            box_t.RcHeader.release(true, rc);
                        } else {
                            alloc.free(rc);
                        }
                    }
                }
            }

            pub fn pointer(self: *@This()) pointer_t {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.pointer(),
                    .Heap => return self.storage.as_large.pointer(),
                    .Shared => return self.storage.as_shared.pointer()
                }
            }

            pub fn const_pointer(self: *const @This()) const_pointer_t {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.const_pointer(),
                    .Heap => return self.storage.as_large.const_pointer(),
                    .Shared => return self.storage.as_shared.const_pointer()
                }
            }

            pub fn size(self: *const @This()) usize {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.size(),
                    .Heap => return self.storage.as_large.size(),
                    .Shared => return self.storage.as_shared.size()
                }
            }

            pub fn capacity(self: *const @This()) usize {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.capacity(),
                    .Heap => return self.storage.as_large.capacity(),
                    .Shared => return self.storage.as_shared.capacity()
                }
            }

            pub fn empty(self: *const @This()) bool {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.storage.as_cache.size() == 0,
                    .Heap => return self.storage.as_large.size() == 0,
                    .Shared => return self.storage.as_shared.size() == 0
                }
            }

            pub fn clear(self: *@This(), alloc: std.mem.Allocator) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => {
                        var cache: *cache_buffer_t = &self.storage.as_cache;
                        cache.pointer()[box_t.max_cache_size] = 0;
                        cache.pointer()[0] = 0;
                    },
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        large.size_ = 0;
                        large.pointer()[0] = 0;
                    },
                    .Shared => {
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            const old_size = rc.capacity();
                            var new_data = try alloc.alloc(char_t, old_size);
                            new_data.ptr[0] = 0;
                            shared.size_ = 0;
                            shared.setCapacity(old_size, .{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            shared.data_ = new_data.ptr;
                            _ = box_t.RcHeader.release(true, rc);
                        } else {
                            rc.size_ = 0;
                            shared.data_[0] = 0;
                        }
                    }
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
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            shared.setCapacity(0, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            shared.size_ = rc.size();
                            try self.assign_init_c(alloc, c);
                            _ = box_t.RcHeader.release(true, rc);
                        } else {
                            const shared_size = rc.size();
                            if (rc.capacity() < shared_size) {
                                const alloc_size: usize = shared_size + (shared_size / 2);
                                const new_rc = try box_t.RcHeader.alloc(alloc, shared_size, alloc_size);
                                @import("Backend/strset.zig").Backend.strset(
                                    char_t, 
                                    new_rc.dataFromHeader(), 
                                    c,
                                    shared_size
                                );
                                shared.data_ = new_rc.data();
                            } else {
                                @import("Backend/strset.zig").Backend.strset(
                                    char_t, 
                                    rc.dataFromHeader(), 
                                    c,
                                    shared_size
                                );
                            }
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
                        cache.pointer()[box_t.max_cache_size] = @intCast(str_size);
                        cache.pointer()[str_size] = 0;
                    },
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        const str_size = length;
                        const alloc_size: usize = str_size + (str_size / 2);
                        var alloc_slice = try alloc.alloc(char_t, alloc_size);
                        large.setCapacity(alloc_size, category_module.Mode{
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
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            shared.setCapacity(0, category_module.Mode{
                                .storage = .Large,
                                .ownership = .Owning
                            });
                            try self.assign_init_str(alloc, str, length);
                            _ = box_t.RcHeader.release(true, rc);
                        } else {
                            const str_size = length;
                            if (rc.capacity() < length) {
                                const alloc_size: usize = str_size + (str_size / 2);
                                const new_rc = try box_t.RcHeader.alloc(alloc, str_size, alloc_size);
                                @import("Backend/strcpy.zig").Backend.strcpy(
                                    char_t, 
                                    new_rc.dataFromHeader(), 
                                    str,
                                    str_size
                                );
                                shared.data_ = new_rc.dataFromHeader();
                            } else {
                                @import("Backend/strcpy.zig").Backend.strcpy(
                                    char_t, 
                                    rc.dataFromHeader(), 
                                    str,
                                    str_size
                                );
                            }
                        }
                    }
                }
            }
        };
    }
};