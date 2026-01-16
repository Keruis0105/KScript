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

            pub fn clone(self: *@This(), alloc: std.mem.Allocator) !@This() {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => return self.shallowCopyInline(),
                    .Heap => {
                        try self.ensureShared(alloc);
                        box_t.RcHeader.retain(true, box_t.RcHeader.headerFromData(self.storage.as_shared.pointer()));
                        return self.shallowCopyShared();
                    },
                    .Shared => {
                        box_t.RcHeader.retain(true, box_t.RcHeader.headerFromData(self.storage.as_shared.pointer()));
                        return self.shallowCopyShared();
                    }
                }
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

            pub fn set(self: *@This(), alloc: std.mem.Allocator, index: usize, c: char_t) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline, .Heap => {
                        self.pointer()[index] = c;
                    },
                    .Shared => {
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            try self.ensureUnique(alloc);
                            self.storage.as_large.pointer()[index] = c;
                        } else {
                            shared.pointer()[index] = c;
                        }
                    }
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
                            shared.toLargeMode(old_size);
                            shared.data_ = new_data.ptr;
                            _ = box_t.RcHeader.release(true, rc);
                        } else {
                            rc.size_ = 0;
                            shared.data_[0] = 0;
                        }
                    }
                }
            }

            pub fn append_c(self: *@This(), alloc: std.mem.Allocator, c: char_t) !void {
                const ptr: const_pointer_t = @ptrCast(&c);
                try self.append_impl(alloc, ptr, 1);
            }

            pub fn append_str(self: *@This(), alloc: std.mem.Allocator, str: const_pointer_t) !void {
                const length = @import("Backend/strlen.zig").Backend.strlen(char_t, str);
                try self.append_impl(alloc, str, length);
            }

            pub fn append_len(self: *@This(), alloc: std.mem.Allocator, ptr: const_pointer_t, len: usize) !void {
                try self.append_impl(alloc, ptr, len);
            }

            fn shallowCopyInline(self: *const @This()) @This() {
                return self.*;
            }

            fn shallowCopyHeap(self: *const @This()) @This() {
                return self.*;
            }

            fn shallowCopyShared(self: *const @This()) @This() {
                return self.*;
            }

            fn copyCache(self: *@This(), str: const_pointer_t, buf_size: usize, length: usize) void {
                var cache: *cache_buffer_t = &self.storage.as_cache;
                @import("Backend/strcpy.zig").Backend.strcpy(
                    char_t,
                    cache.pointer() + buf_size,
                    str,
                    length
                );
                cache.data_[box_t.max_cache_size] = @intCast(buf_size + length);
            }

            fn copyLarge(self: *@This(), str: const_pointer_t, buf_size: usize, length: usize) void {
                var large: *box_data_t = &self.storage.as_large;
                @import("Backend/strcpy.zig").Backend.strcpy(
                    char_t,
                    large.pointer() + buf_size,
                    str,
                    length
                );
                large.size_ = buf_size + length;
            }

            fn copyShared(self: *@This(), str: const_pointer_t, buf_size: usize, length: usize) void {
                var shared: *box_shared_t = &self.storage.as_shared;
                @import("Backend/strcpy.zig").Backend.strcpy(
                    char_t,
                    shared.pointer() + buf_size,
                    str, 
                    length
                );
                var rc = box_t.RcHeader.headerFromData(shared.pointer());
                _ = @atomicRmw(usize, &rc.size_, .Add, buf_size + length, .seq_cst);
            }

            fn heapify_cache(self: *@This(), large: *box_data_t, alloc: std.mem.Allocator, new_size: usize) !void {
                var cache: *cache_buffer_t = &self.storage.as_cache;
                var alloc_slice = try alloc.alloc(char_t, new_size);
                const data = alloc_slice.ptr;
                @import("Backend/strcpy.zig").Backend.strcpy(
                    char_t,
                    data,
                    cache.const_pointer(),
                    cache.size()
                );
                large.data_ = data;
                large.setCapacity(new_size, .{
                    .storage = .Large,
                    .ownership = .Owning
                });
                large.size_ = cache.size();
            }

            fn new_space(self: *@This(), large: *box_data_t, alloc: std.mem.Allocator, new_size: usize) !void {
                _ = self;
                const old_ptr = large.pointer();
                var alloc_slice = try alloc.alloc(char_t, new_size);
                const data = alloc_slice.ptr;
                @import("Backend/strcpy.zig").Backend.strcpy(
                    char_t,
                    data,
                    large.const_pointer(),
                    large.size()
                );
                alloc.free(old_ptr[0..large.size()]);
                large.data_ = data;
                large.setCapacity(new_size, .{
                    .storage = .Large,
                    .ownership = .Owning
                });
            }

            fn respace(self: *@This(), comptime init_heap: bool, alloc: std.mem.Allocator, new_size: usize) !void {
                const large: *box_data_t = &self.storage.as_large;
                if (init_heap) {
                    try self.heapify_cache(large, alloc, new_size);
                }
                try self.new_space(large, alloc, new_size);
            }

            fn ensureShared(self: *@This(), alloc: std.mem.Allocator) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline, .Shared => return,
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        const len = large.size();
                        const cap = large.capacity();
                        const large_data = large.pointer();
                        var rc = try box_t.RcHeader.alloc(alloc, len, cap);
                        const data = rc.dataFromHeader();
                        @import("Backend/strcpy.zig").Backend.strcpy(
                            char_t,
                            data, 
                            large_data, 
                            len
                        );
                        large.toSharedMode(0);
                        var shared: *box_shared_t = &self.storage.as_shared;
                        shared.data_ = data;
                        shared.size_ = len;
                        shared.setCapacity(cap, .{
                            .storage = .Large,
                            .ownership = .Shared
                        });
                    }
                }
            }

            fn ensureUnique(self: *@This(), alloc: std.mem.Allocator) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline, .Heap => return,
                    .Shared => {
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc: *box_t.RcHeader = box_t.RcHeader.headerFromData(shared.pointer());
                        const len: usize = rc.size();
                        const cap: usize = rc.capacity();
                        var alloc_slice = try alloc.alloc(char_t, cap);
                        @import("Backend/strcpy.zig").Backend.strcpy(
                            char_t,
                            alloc_slice.ptr,
                            shared.const_pointer(),
                            len
                        );
                        shared.toLargeMode(cap);
                        shared.size_ = len;
                        shared.data_ = alloc_slice.ptr;
                        shared.pointer()[len] = 0;
                        _ = box_t.RcHeader.release(true, rc);
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
                            shared.toLargeMode(0);
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

            fn append_impl(self: *@This(), alloc: std.mem.Allocator, str: const_pointer_t, length: usize) !void {
                switch (box_t.modeTag(&self.storage)) {
                    .Inline => {
                        var cache: *cache_buffer_t = &self.storage.as_cache;
                        const cache_size = cache.size();
                        const next_size = cache_size + length;
                        if (next_size < box_t.max_cache_size) {
                            self.copyCache(str, cache_size, length);
                            cache.pointer()[next_size] = 0;
                            return;
                        }
                        try self.respace(true, alloc, next_size + (next_size / 2));
                        var large: *box_data_t = &self.storage.as_large;
                        const large_size = large.size();
                        self.copyLarge(str, large_size, length);
                        large.pointer()[next_size] = 0;
                    },
                    .Heap => {
                        var large: *box_data_t = &self.storage.as_large;
                        const large_size = large.size();
                        const large_cap = large.capacity();
                        const next_size = large_size + length;
                        if (next_size >= large_cap) {
                            try self.respace(false, alloc, next_size + (next_size / 2));   
                        }
                        self.copyLarge(str, large_size, length);
                        large.pointer()[next_size] = 0;
                    },
                    .Shared => {
                        var shared: *box_shared_t = &self.storage.as_shared;
                        var rc = box_t.RcHeader.headerFromData(shared.pointer());
                        if (@atomicLoad(usize, &rc.refcount_, .seq_cst) > 1) {
                            try self.ensureUnique(alloc);
                            try self.append_impl(alloc, str, length);
                            return;
                        }
                        const shared_size = rc.size();
                        const shared_cap = rc.capacity();
                        const next_size = shared_size + length;
                        if (next_size >= shared_cap) {
                            var new_rc = try box_t.RcHeader.alloc(alloc, shared_size, next_size + (next_size / 2));
                            @import("Backend/strcpy.zig").Backend.strcpy(
                                char_t, 
                                new_rc.dataFromHeader(), 
                                shared.const_pointer(), 
                                shared_size
                            );
                            shared.data_ = new_rc.dataFromHeader();
                        }
                        self.copyShared(str, shared_size, length);
                        shared.pointer()[next_size] = 0;
                    }
                }
            }
        };
    }
};