const std = @import("std");
const category_module = @import("Category.String.zig").impl;
const box_module = @import("Box.String.zig").impl;

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

            pub fn init_slice(slice: []const char_t) !@This() {
                return init_str(slice.ptr);
            }

            pub fn init_copy(other: *const @This()) !@This() {
                var instance: @This() = .{};
                try if (other.isSmall()) instance.copySmall(other)
                    else instance.copyMedium(other);
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
                if (!self.isSmall()) {
                    const op: ?pointer_t = self.storage.as_ml.data_;
                    if (op != null) {
                        var alloc: alloc_t = .{};
                        alloc.deallocator(self.storage.as_ml.data_, self.storage.as_ml.capacity() + 1);
                    }
                }
            }

            //

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

            pub fn append_slice(self: *@This(), str_slice: []const char_t) !*@This() {
                const s = str_slice;
                try if (self.isSmall()) self.appendSmall(s.ptr) else self.appendMedium(s.ptr);
                return self;
            }

            //

            fn pointer(self: *@This()) pointer_t {
                if (self.isSmall()) return @ptrCast(&self.storage.as_small[0])
                    else return self.storage.as_ml.data_;
            }

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

            fn initSmall(self: *@This(), d: const_pointer_t, s: usize) void {
                std.debug.assert(s < max_small_size);
                string_trait.copy(&self.storage.as_small, d, s);
                setSmallSize(self, s);
            }

            fn initMedium(self: *@This(), d: const_pointer_t, s: usize) !void {
                var alloc: alloc_t = .{};
                self.storage.as_ml.data_ = try alloc.allocator(s + 1);
                string_trait.copy(self.storage.as_ml.data_, d, s);
                self.storage.as_ml.data_[s] = 0;
                self.storage.as_ml.size_ = s;
                self.storage.as_ml.setCapacity(s, .isMedium);
            }

            fn copySmall(self: *@This(), other: *const @This()) void {
                self.storage.as_small = other.storage.as_small;
            }

            fn copyMedium(self: *@This(), other: *const @This()) !void {
                const other_len: usize = other.storage.as_ml.size_;
                var alloc: alloc_t = .{};
                self.storage.as_ml.data_ = try alloc.allocator(other_len + 1);
                string_trait.copy(self.storage.as_ml.data_, other.storage.as_ml.data_, other_len);
                self.storage.as_ml.size_ = other_len;
                self.storage.as_ml.setCapacity(other_len + 1, .isMedium);
                self.storage.as_ml.data_[other_len] = 0;
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

                var alloc: alloc_t = .{};
                const mallocPtr: pointer_t = try alloc.allocator(s + 1);
                string_trait.copy(mallocPtr, &self.storage.as_small, old_size);
                self.storage.as_ml.data_ = mallocPtr;
                self.storage.as_ml.size_ = old_size;
                self.storage.as_ml.setCapacity(s, .isMedium);
                self.storage.as_ml.data_[old_size] = 0;
            }

            fn reserverMedium(self: *@This(), s: usize) !void {
                if (s < self.storage.as_ml.capacity()) return;

                const old_size: usize = self.size();

                var alloc: alloc_t = .{};
                const mallocPtr: pointer_t = try alloc.allocator(s + 1);
                string_trait.copy(mallocPtr, self.storage.as_ml.data_, old_size);
                alloc.deallocator(self.storage.as_ml.data_, old_size + 1);
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
        };
    }
};