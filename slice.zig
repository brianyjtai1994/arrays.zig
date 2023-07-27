const std = @import("std");
const expect = std.testing.expect;

test "type of array/slice" {
    var a1 = [_]u8{ 1, 2, 3, 4, 5 };
    var p1 = &a1;
    var s1: []u8 = p1; // pointer to slice
    var p2 = s1.ptr;

    try expect(@TypeOf(a1) == [5]u8);
    try expect(@TypeOf(p1) == *[5]u8);
    try expect(@TypeOf(s1) == []u8);
    try expect(@TypeOf(p2) == [*]u8);
}

test "pointer addresses of array/slice" {
    var a1 = [_]u8{ 1, 2, 3, 4, 5 };
    var s1: []u8 = &a1;
    var s2: []u8 = &a1;

    try expect(@intFromPtr(&a1) == @intFromPtr(s1.ptr));
    try expect(@intFromPtr(&a1) == @intFromPtr(s2.ptr));

    try expect(@intFromPtr(&s1) != @intFromPtr(&s2));

    try expect(@intFromPtr(&(a1[0])) == @intFromPtr(&(s1[0])));
    try expect(@intFromPtr(&(a1[0])) == @intFromPtr(&(s2[0])));
    try expect(@intFromPtr(&(s1[0])) == @intFromPtr(&(s2[0])));
}
