const std = @import("std");
const constants = @import("constants.zig");

pub const AnsiColor = enum {
    red,
    yellow,
    blue,
    orange,
    white,
    bright_green,
    grey,
    reset,
};

pub fn getRandomColorForCell(cell_type: constants.CellType, rng: anytype) AnsiColor {
    return switch (cell_type) {
        .star => .yellow,
        .foliage => .bright_green,
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
    // Lights can use various colors
    const colors = [_]AnsiColor{ .red, .blue, .yellow, .white, .grey, .magenta };
    return colors[rng.uintLessThan(usize, colors.len)];
}

pub fn getColorCode(color: AnsiColor) []const u8 {
    return switch (color) {
        .red => "\x1b[91m", // bright red
        .yellow => "\x1b[93m", // bright yellow
        .blue => "\x1b[94m", // bright blue
        .orange => "\x1b[38;5;214m", // 256-color orange
        .white => "\x1b[97m", // bright white
        .bright_green => "\x1b[92m", // bright green (foliage)
        .grey => "\x1b[90m",
        .reset => "\x1b[0m",
    };
}

pub fn applyColor(file: std.fs.File, color: AnsiColor) !void {
    try file.writeAll(getColorCode(color));
}

pub fn resetColor(file: std.fs.File) !void {
    try file.writeAll(getColorCode(.reset));
}
