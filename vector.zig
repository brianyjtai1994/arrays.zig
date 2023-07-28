const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

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
        vec.dat[3] = 4;

        try testing.expect(vec.dat.len == 10);
        try testing.expect(vec.size == 10);
        try testing.expect(vec.dat[3] == 4);
    }
}
