const std = @import("std");
const constants = @import("constants.zig");

pub const AnsiColor = enum {
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    grey,
    reset,
};

const ColorCodes = std.ComptimeStringMap([]const u8, .{
    .{ .red = "\x1b[31m" },
    .{ .green = "\x1b[32m" },
    .{ .yellow = "\x1b[33m" },
    .{ .blue = "\x1b[34m" },
    .{ .magenta = "\x1b[35m" },
    .{ .cyan = "\x1b[36m" },
    .{ .white = "\x1b[37m" },
    .{ .grey = "\x1b[90m" },
    .{ .reset = "\x1b[0m" },
});

pub fn getRandomColorForCell(cell_type: constants.CellType, rng: anytype) AnsiColor {
    return switch (cell_type) {
        .star => .yellow,
        .foliage => .green,
        .trunk => .white,
        .ornament => getRandomOrnamentColor(rng),
        .light => getRandomLightColor(rng),
    };
}

fn getRandomOrnamentColor(rng: anytype) AnsiColor {
    const colors = [_]AnsiColor{ .red, .blue, .yellow, .white, .grey, .magenta };
    return colors[rng.uintLessThan(usize, colors.len)];
}

fn getRandomLightColor(rng: anytype) AnsiColor {
    // Lights can also be green
    const colors = [_]AnsiColor{ .red, .green, .yellow, .blue, .white, .grey, .magenta, .yellow };
    return colors[rng.uintLessThan(usize, colors.len)];
}

pub fn getColorCode(color: AnsiColor) []const u8 {
    return ColorCodes.get(@tagName(color)).?;
}

pub fn applyColor(writer: std.fs.File.Writer, color: AnsiColor) !void {
    try writer.writeAll(getColorCode(color));
}

pub fn resetColor(writer: std.fs.File.Writer) !void {
    try writer.writeAll(getColorCode(.reset));
}
