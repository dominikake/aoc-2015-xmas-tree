const std = @import("std");
const colors = @import("src/colors.zig");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

test "magenta color exists in enum" {
    const magenta_color = colors.AnsiColor.magenta;
    try expect(magenta_color == .magenta);
}

test "magenta color has valid escape code" {
    const magenta_code = colors.getColorCode(.magenta);
    try expectEqualStrings("\x1b[95m", magenta_code);
}

test "all colors have valid escape codes" {
    inline for (std.meta.fields(colors.AnsiColor)) |field| {
        const color = @field(colors.AnsiColor, field.name);
        const code = colors.getColorCode(color);
        try expect(code.len > 0, "Color {s} has empty escape code", .{field.name});
    }
}

test "color codes are correct format" {
    const red_code = colors.getColorCode(.red);
    const green_code = colors.getColorCode(.bright_green);
    const yellow_code = colors.getColorCode(.yellow);
    const reset_code = colors.getColorCode(.reset);

    try expectEqualStrings("\x1b[91m", red_code);
    try expectEqualStrings("\x1b[92m", green_code);
    try expectEqualStrings("\x1b[93m", yellow_code);
    try expectEqualStrings("\x1b[0m", reset_code);
}

test "ornament colors include magenta" {
    var prng = std.Random.DefaultPrng.init(42);
    const ornament_color = colors.getRandomOrnamentColor(prng.random());

    // Should return one of the ornament colors including magenta
    const valid_colors = [_]colors.AnsiColor{ .red, .blue, .yellow, .white, .grey, .magenta };
    var found = false;
    for (valid_colors) |valid_color| {
        if (ornament_color == valid_color) {
            found = true;
            break;
        }
    }
    try expect(found, "getRandomOrnamentColor returned invalid color");
}

test "light colors include magenta" {
    var prng = std.Random.DefaultPrng.init(42);
    const light_color = colors.getRandomLightColor(prng.random());

    // Should return one of the light colors including magenta
    const valid_colors = [_]colors.AnsiColor{ .red, .blue, .yellow, .white, .grey, .magenta };
    var found = false;
    for (valid_colors) |valid_color| {
        if (light_color == valid_color) {
            found = true;
            break;
        }
    }
    try expect(found, "getRandomLightColor returned invalid color");
}
