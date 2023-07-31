const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

fn betterMemSize(given: usize) usize {
    var better: usize = given;
    better +|= 8 + (better >> 1);
    while (better < given) {
        better +|= 8 + (better >> 1);
    }
    return better;
}

fn Vector(comptime T: type) type {
    return struct {
        const Self = @This();

        dat: []T, // data
        size: usize, // allocated size
        owner: Allocator, // allocator as owner

        fn init(owner: Allocator, size: usize) Allocator.Error!Self {
            if (size == 0) return Self{
                .dat = &[_]T{},
                .size = 0,
                .owner = owner,
            };

            if (@sizeOf(T) == 0) return Self{
                .dat = &[_]T{},
                .size = std.math.maxInt(usize),
                .owner = owner,
            };

            const new_mem = try owner.alignedAlloc(T, @alignOf(T), size);
            return Self{
                .dat = new_mem,
                .size = new_mem.len,
                .owner = owner,
            };
        }

        inline fn setIndex(self: Self, ind: usize, val: T) void {
            self.dat[ind] = val;
        }

        inline fn getIndex(self: Self, ind: usize) T {
            return self.dat[ind];
        }

        fn push(self: *Self, val: T) Allocator.Error!void {
            if (@sizeOf(T) == 0) {
                self.size = std.math.maxInt(usize);
            } else {
                var new_size: usize = self.dat.len + 1;
                if (self.size < new_size) {
                    new_size = betterMemSize(self.size);
                }

                const old_mem = self.dat.ptr[0..self.size];
                if (self.owner.resize(old_mem, new_size)) {
                    self.size = new_size;
                } else {
                    const new_mem = try self.owner.alignedAlloc(T, @alignOf(T), new_size);
                    @memcpy(new_mem[0..self.dat.len], self.dat);
                    self.owner.free(old_mem);
                    self.dat.ptr = new_mem.ptr;
                    self.size = new_mem.len;
                }
            }

            std.debug.assert(self.dat.len < self.size);

            self.dat.len += 1;
            self.dat[self.dat.len - 1] = val;
        }
    };
}

test "Vector.init" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    {
        var vec = try Vector(i32).init(arena.allocator(), 0);

        try testing.expect(vec.dat.len == 0);
        try testing.expect(vec.size == 0);
    }
    {
        var vec = try Vector(u0).init(arena.allocator(), 20);

        try testing.expect(vec.dat.len == 0);
        try testing.expect(vec.size == std.math.maxInt(usize));
    }
    {
        var vec = try Vector(i32).init(arena.allocator(), 10);
        vec.setIndex(3, 4);

        try testing.expect(vec.dat.len == 10);
        try testing.expect(vec.size == 10);
        try testing.expect(vec.getIndex(3) == 4);
    }
}

test "Vector.push" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    {
        var vec = try Vector(i32).init(arena.allocator(), 0);
        for (0..10) |i| {
            try vec.push(@intCast(i));
            try testing.expect(vec.getIndex(i) == i);
        }
        try testing.expect(vec.dat.len == 10);
    }
}
