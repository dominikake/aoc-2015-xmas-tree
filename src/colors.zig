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
    magenta,
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
        .red => "\x1b[31m", // normal red
        .yellow => "\x1b[33m", // normal yellow
        .blue => "\x1b[34m", // normal blue
        .orange => "\x1b[38;5;214m", // 256-color orange
        .white => "\x1b[37m", // normal white
        .bright_green => "\x1b[32m", // normal green (foliage)
        .grey => "\x1b[30m", // normal black (for better visibility)
        .magenta => "\x1b[35m", // normal magenta
        .reset => "\x1b[0m",
    };
}
pub fn applyColor(file: std.fs.File, color: AnsiColor) !void {
    try file.writeAll(getColorCode(color));
}

pub fn resetColor(file: std.fs.File) !void {
    try file.writeAll(getColorCode(.reset));
}

// Tests
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

test "magenta color exists in enum" {
    const magenta_color = AnsiColor.magenta;
    try expect(magenta_color == .magenta);
}

test "magenta color has valid escape code" {
    const magenta_code = getColorCode(.magenta);
    try expectEqualStrings("\x1b[35m", magenta_code);
}

test "all colors have valid escape codes" {
    inline for (std.meta.fields(AnsiColor)) |field| {
        const color = @field(AnsiColor, field.name);
        const code = getColorCode(color);
        try expect(code.len > 0);
    }
}

test "color codes are correct format" {
    const red_code = getColorCode(.red);
    const green_code = getColorCode(.bright_green);
    const yellow_code = getColorCode(.yellow);
    const reset_code = getColorCode(.reset);

    try expectEqualStrings("\x1b[31m", red_code);
    try expectEqualStrings("\x1b[32m", green_code);
    try expectEqualStrings("\x1b[33m", yellow_code);
    try expectEqualStrings("\x1b[0m", reset_code);
}
