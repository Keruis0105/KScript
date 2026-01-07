const std = @import("std");
const category_module = @import("Category.String.zig").impl;
const box_module = @import("Box.String.zig").impl;
const shared_block_module = @import("SharedBlock.String.zig").impl;

pub const impl = struct {
    pub fn Core(comptime Tr: type, comptime Alloc: type) type {
        return struct {
            pub const string_trait = Tr;
            const     type_size: usize = string_trait.type_size;
            pub const char_t = string_trait.char_t;
            pub const pointer_t = string_trait.pointer_t;
            pub const const_pointer_t = string_trait.const_pointer_t;
            pub const alloc_t = Alloc;

            const box_t = box_module.Box(Tr);
            const shared_t = shared_block_module.SharedBlock(Tr, alloc_t);

            storage: box_t.Storage = undefined,    

            const box_value_t = box_t.box_value_t;
            const box_buffer_t = box_t.box_buffer_t;

            const last_char = @sizeOf(box_value_t) - 1;
            pub const max_small_size = last_char / type_size;

            pub fn init() @This() {
                var instance: @This() = .{};
                instance.reset();
                return instance;
            }

            pub fn init_size(s: usize) !@This() {
                var instance: @This() = init();
                _ = try instance.reserve(s);
                return instance;
            }

            pub fn init_c(c: char_t) @This() {
                var instanc: @This() = .{};
                instanc.reset();
                instanc.storage.as_small[0] = c;
                return instanc;
            }

            pub fn init_str(str: ?const_pointer_t) !@This() {
                var instance: @This() = .{};
                if (str) |s| {
                    const length = string_trait.length(s);
                    if (length < max_small_size)
                        initSmall(&instance, s, length)
                    else 
                        try initMedium(&instance, s, length);
                } else {
                    instance.reset();
                }
                return instance;
            }

            pub fn init_heap(s: usize) !@This() {
                var instance: @This() = .{};
                try initMedium(&instance, "", s);
                return instance;
            }

            pub fn init_slice(slice: []const char_t) !@This() {
                var instance: @This() = .init();
                if (slice.len > 0) {
                    _ = try instance.append_slice(slice);
                }
                return instance;
            }

            pub fn init_copy(other: *const @This()) !@This() {
                var instance: @This() = .{};
                switch (other.getCategory()) {
                    .isSmall => {
                        instance.copySmall(other);
                    },
                    .isMedium => {
                        try instance.copyMedium(other);
                    },
                    .isShared => {
                        try instance.copyShared(other);
                    }
                }
                return instance;
            }

            pub fn init_move(other: *@This()) @This() {
                var instance: @This() = .{};
                instance.storage = other.storage;
                
                if (!other.isSmall()) {
                    var op: ?pointer_t = other.storage.as_ml.data_;
                    op = null;
                    other.storage.as_ml.size_ = 0;
                    other.storage.as_ml.capcaity_ = 0;
                }

                return instance;
            }

            pub fn deinit(self: *@This()) void {
                switch (self.getCategory()) {
                    .isSmall => {

                    },
                    .isMedium => {
                        const op: ?pointer_t = self.storage.as_ml.data_;
                        if (op != null) {
                            alloc_t.deallocator(self.storage.as_ml.data_, self.storage.as_ml.capacity() + 1);
                        }
                    },
                    .isShared => {
                        const block = self.getSharedBlock();
                        block.release(self.storage.as_ml.capacity() + 1);
                    }
                }
            }

            //

            pub fn clone(self: *const @This(), alloc: std.mem.Allocator) !@This() {
                var out: @This() = .init();
                if (self.size() == 0) return out;
                switch (self.getCategory()) {
                    .isSmall => {
                        out.storage.as_small = self.storage.as_small;
                    },
                    .isMedium => {
                        const len: usize = self.storage.as_ml.size_;
                        out.storage.as_ml.data_ = (try alloc.alloc(char_t, len + 1)).ptr;
                        string_trait.copy(out.storage.as_ml.data_, self.storage.as_ml.data_, len);
                        out.storage.as_ml.size_ = len;
                        out.storage.as_ml.setCapacity(len + 1, .isMedium);
                        out.storage.as_ml.data_[len] = 0;
                    },
                    .isShared => {
                        const block = self.getSharedBlock();
                        block.retain();
                        out.storage.as_ml.data_ = self.storage.as_ml.data_;
                        out.storage.as_ml.size_ = self.storage.as_ml.size_;
                        out.storage.as_ml.capcaity_ = self.storage.as_ml.capcaity_;
                    }
                }
                return out;
            }

            pub fn shared(self: *const @This()) !@This() {
                var out: @This() = .init();
                const block = try shared_t
                    .createSharedBlock(self.pointer());
                out.storage.as_ml.data_ = @ptrCast(block);
                out.storage.as_ml.size_ = self.size();
                out.storage.as_ml.setCapacity(self.capacity(), .isShared);
                return out;
            }

            pub fn size(self: *const @This()) usize {
                return if (isSmall(self)) return @intCast(self.storage.as_small[max_small_size])
                    else self.storage.as_ml.size_;
            }

            pub fn capacity(self: *@This()) usize {
                if (self.isSmall()) return max_small_size
                    else return self.storage.as_ml.capacity();
            }

            pub fn data(self: *@This()) pointer_t {
                if (self.isSmall()) return @ptrCast(&self.storage.as_small[0])
                    else return self.storage.as_ml.data_;
            }

            pub fn as_slice(self: *const @This()) []const char_t {
                if (self.isSmall()) return self.storage.as_small[0..self.size()] 
                    else return self.storage.as_ml.data_[0..self.size()];
            }

            pub fn as_c_str(self: *@This()) [*c]const char_t {
                if (self.isSmall()) return @ptrCast(&self.storage.as_small[0])
                    else return @ptrCast(self.storage.as_ml.data_);
            }

            pub fn empty(self: *@This()) bool {
                if (self.isSmall()) return self.storage.as_small[max_small_size] == 0
                    else return self.storage.as_ml.size_ == 0;
            }

            pub fn clear(self: *@This()) *@This() {
                if (self.isSmall()) self.clearSmall()
                    else self.clearMedium();
            }

            pub fn begin(self: *@This()) pointer_t {
                return self.data();
            }

            pub fn end(self: *@This()) pointer_t {
                if (self.isSmall()) return @ptrCast(&self.storage.as_small[self.size() - 1])
                    else return @ptrCast(&self.storage.as_ml.data_[self.storage.as_ml.size_ - 1]);
            }

            pub fn reserve(slef: *@This(), s: usize) !*@This() {
                if (slef.isSmall()) try slef.reserverSmall(s)
                    else try slef.reserverMedium(s);
                return slef;
            }

            pub fn resize(self: *@This(), s: usize, fill_char: char_t) !*@This() {
                const old_size: usize = self.size();
                if (s < old_size) {
                    if (self.isSmall())
                        self.setSmallSize(s)
                    else {
                        self.storage.as_ml.size_ = s;
                        self.storage.as_ml.data_[s] = 0;
                    }
                    return self;
                }

                try if (self.isSmall()) self.resizeSmall(s, fill_char)
                    else self.resizeMedium(s, fill_char);

                return self;
            }

            pub fn append(self: *@This(), str: ?const_pointer_t) !*@This() {
                if (str) |s| {
                    try if (self.isSmall()) self.appendSmall(s) else self.appendMedium(s);
                }
                return self;
            }

            pub fn append_byte(self: *@This(), b: char_t) !*@This() {
                var tmp: [1]char_t = .{b};
                return try self.append_slice(&tmp);
            }

            pub fn append_slice(self: *@This(), str_slice: []const char_t) !*@This() {
                try if (self.isSmall()) self.appendSmallSlice(str_slice) else self.appendMediumSlice(str_slice);
                return self;
            }

            pub fn pointer(self: *@This()) pointer_t {
                switch (self.getCategory()) {
                    .isSmall => {
                        return @ptrCast(&self.storage.as_small[0]);
                    },
                    .isMedium => {
                        return self.storage.as_ml.data_;
                    },
                    .isShared => {
                        return self.storage.as_ml.data_.data_;
                    }
                }
            }

            pub fn cpointer(self: @This()) const_pointer_t {
                return self.pointer();
            }

            //

            fn reset(self: *@This()) void {
                setSmallSize(self, 0);
            }

            fn setSmallSize(self: *@This(), s: usize) void {
                std.debug.assert(s < max_small_size);
                self.storage.as_small[max_small_size] = @intCast(s);
                self.storage.as_small[s] = 0;
            }

            fn isSmall(self: *const @This()) bool {
                return box_t.category(&self.storage) == .isSmall;
            }

            fn getCategory(self: *const @This()) category_module.Category {
                return box_t.category(&self.storage);
            }

            fn getSharedBlock(self: *const @This()) *shared_t {
                std.debug.assert(self.getCategory() == .isShared);
                return @ptrCast(@alignCast(self.storage.as_ml.data_));
            }

            fn initSmall(self: *@This(), d: const_pointer_t, s: usize) void {
                std.debug.assert(s < max_small_size);
                string_trait.copy(&self.storage.as_small, d, s);
                setSmallSize(self, s);
            }

            fn initMedium(self: *@This(), d: const_pointer_t, s: usize) !void {
                self.storage.as_ml.data_ = try alloc_t.allocator(s + 1);
                string_trait.copy(self.storage.as_ml.data_, d, s);
                self.storage.as_ml.data_[s] = 0;
                self.storage.as_ml.size_ = s;
                self.storage.as_ml.setCapacity(s, .isMedium);
            }

            fn copySmall(self: *@This(), other: *const @This()) void {
                std.debug.assert(other.getCategory() == .isSmall);
                self.storage.as_small = other.storage.as_small;
            }

            fn copyMedium(self: *@This(), other: *const @This()) !void {
                std.debug.assert(other.getCategory() == .isMedium);
                const other_len: usize = other.storage.as_ml.size_;
                self.storage.as_ml.data_ = try alloc_t.allocator(other_len + 1);
                string_trait.copy(self.storage.as_ml.data_, other.storage.as_ml.data_, other_len);
                self.storage.as_ml.size_ = other_len;
                self.storage.as_ml.setCapacity(other_len + 1, .isMedium);
                self.storage.as_ml.data_[other_len] = 0;
            }

            fn copyShared(self: *@This(), other: *const @This()) !void {
                std.debug.assert(other.getCategory() == .isShared);
                const block = other.getSharedBlock();
                block.retain();
                self.storage.as_ml.data_ = other.storage.as_ml.data_;
                self.storage.as_ml.size_ = other.storage.as_ml.size_;
                self.storage.as_ml.capcaity_ = other.storage.as_ml.capcaity_;
            }

            fn clearSmall(self: *@This()) void {
                self.storage.as_small = 0;
                self.storage.as_small[0] = 0;
            }

            fn clearMedium(self: *@This()) void {
                self.storage.as_ml.size_ = 0;
                if (self.storage.as_ml.data_) {
                    self.storage.as_ml.data_[0] = 0;
                }
            }

            fn reserverSmall(self: *@This(), s: usize) !void {
                if (s < max_small_size) return;

                const old_size: usize = self.size();

                const mallocPtr: pointer_t = try alloc_t.allocator(s + 1);
                string_trait.copy(mallocPtr, &self.storage.as_small, old_size);
                self.storage.as_ml.data_ = mallocPtr;
                self.storage.as_ml.size_ = old_size;
                self.storage.as_ml.setCapacity(s, .isMedium);
                self.storage.as_ml.data_[old_size] = 0;
            }

            fn reserverMedium(self: *@This(), s: usize) !void {
                if (s < self.storage.as_ml.capacity()) return;

                const old_size: usize = self.size();

                const mallocPtr: pointer_t = try alloc_t.allocator(s + 1);
                string_trait.copy(mallocPtr, self.storage.as_ml.data_, old_size);
                alloc_t.deallocator(self.storage.as_ml.data_, old_size + 1);
                self.storage.as_ml.data_ = mallocPtr;
                self.storage.as_ml.size_ = old_size;
                self.storage.as_ml.setCapacity(s, .isMedium);
                self.storage.as_ml.data_[old_size] = 0;
            }

            fn resizeSmall(self: *@This(), s: usize, fill_char: char_t) !void {
                const old_size: usize = self.size();
                if (s < max_small_size) {
                    try self.reserverSmall(s);
                    string_trait.assign(
                        @ptrCast(&self.storage.as_small[old_size]),
                        fill_char,
                        s - old_size
                    );

                    self.setSmallSize(s);
                } else { 
                    _ = try self.reserve(s);
                        string_trait.assign(
                        @ptrCast(&self.storage.as_ml.data_[old_size]),
                        fill_char,
                        s - old_size
                    );

                    self.storage.as_ml.size_ = s;
                    self.storage.as_ml.data_[s] = 0;
                }
            }

            fn resizeMedium(self: *@This(), s: usize, fill_char: char_t) !void {
                const old_size: usize = self.size();
                if (s > self.storage.as_ml.capacity()) try self.reserverMedium(s);
                
                string_trait.assign(
                    @ptrCast(&self.storage.as_ml.data_[old_size]),
                    fill_char,
                    s - old_size
                );

                self.storage.as_ml.size_ = s;
                self.storage.as_ml.data_[s] = 0;
            }

            fn appendSmall(self: *@This(), str: const_pointer_t) !void {
                const other_len = string_trait.length(str);
                if (other_len == 0) return;
                const old_size = self.size();
                const new_size = old_size + other_len;
                if (new_size < max_small_size) {
                    const old_ptr = &self.storage.as_small[old_size];
                    string_trait.copy(@ptrCast(old_ptr), str, other_len);
                    self.setSmallSize(new_size);
                    return;
                }
                
                try self.reserverSmall(new_size);
                string_trait.copy(@ptrCast(&self.storage.as_ml.data_[old_size]), str, other_len);
                self.storage.as_ml.size_ = new_size;
                self.storage.as_ml.data_[new_size] = 0;
            }

            fn appendMedium(self: *@This(), str: const_pointer_t) !void {
                const other_len = string_trait.length(str);
                if (other_len == 0) return;
                const old_size = self.size();
                const new_size = old_size + other_len;
                if (new_size > self.capacity()) {
                    _ = try self.reserve(new_size);
                }

                string_trait.copy(@ptrCast(&self.storage.as_ml.data_[old_size]), str, other_len);

                self.storage.as_ml.size_ = new_size;
                self.storage.as_ml.data_[new_size] = 0;
            }

            fn appendSmallSlice(self: *@This(), slice: []const char_t) !void {
                const other_len = slice.len;
                if (other_len == 0) return;

                const old_size = self.size();
                const new_size = old_size + other_len;

                if (new_size < max_small_size) {
                    string_trait.copy(
                        @ptrCast(&self.storage.as_small[old_size]),
                        slice.ptr,
                        other_len,
                    );
                    self.setSmallSize(new_size);
                    return;
                }

                try self.reserverSmall(new_size);
                string_trait.copy(
                    self.storage.as_ml.data_ + old_size,
                    slice.ptr,
                    other_len,
                );
                self.storage.as_ml.size_ = new_size;
                self.storage.as_ml.data_[new_size] = 0;
            }

            fn appendMediumSlice(self: *@This(), slice: []const char_t) !void {
                const other_len = slice.len;
                if (other_len == 0) return;

                const old_size = self.size();
                const new_size = old_size + other_len;

                if (new_size > self.capacity()) {
                    _ = try self.reserve(new_size);
                }

                string_trait.copy(
                    self.storage.as_ml.data_ + old_size,
                    slice.ptr,
                    other_len,
                );
                self.storage.as_ml.size_ = new_size;
                self.storage.as_ml.data_[new_size] = 0;
            }
        };
    }
};