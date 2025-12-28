const std = @import("std");
const tree = @import("../src/tree.zig");
const constants = @import("../src/constants.zig");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "tree generation produces valid structure" {
    const tree_state = tree.TreeState.init();

    // Check that tree has expected number of lines
    try expect(tree_state.width_by_line.len == constants.TREE_HEIGHT);

    // Check that line 0 has the star
    try expect(tree_state.width_by_line[0] == 1);
    try expect(tree_state.cells[0][0].cell_type == constants.CellType.star);

    // Check that trunk exists
    const trunk_start = constants.TREE_LINES + 1;
    try expect(tree_state.width_by_line[trunk_start] == constants.TRUNK_WIDTH);
}

test "decoration placement respects clustering limits" {
    var prng = std.Random.DefaultPrng.init(42); // Fixed seed for reproducibility
    var tree_state = tree.TreeState.init();
    tree_state.rng = prng;

    // Regenerate tree with known seed
    tree_state.generateTree();

    // Use prng to avoid unused warning
    _ = prng.random().uintLessThan(usize, 1);

    // Check that no line has more than MAX_CONSECUTIVE_DECORATIONS
    for (1..constants.TREE_LINES + 1) |line_num| {
        const width = tree_state.width_by_line[line_num];
        if (width > 2) {
            var consecutive: usize = 0;
            for (1..width - 1) |col| {
                const cell = tree_state.cells[line_num][col];
                if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                    consecutive += 1;
                    try expect(consecutive <= constants.MAX_CONSECUTIVE_DECORATIONS, "Too many consecutive decorations at line {}, col {}", .{ line_num, col });
                } else {
                    consecutive = 0;
                }
            }
        }
    }
}

test "decoration density stays within reasonable bounds" {
    var prng = std.Random.DefaultPrng.init(42);
    var tree_state = tree.TreeState.init();
    tree_state.rng = prng;

    tree_state.generateTree();

    // Use prng to avoid unused warning
    _ = prng.random().uintLessThan(usize, 1);

    // Calculate overall decoration density
    var total_positions: usize = 0;
    var decoration_count: usize = 0;

    for (1..constants.TREE_LINES + 1) |line_num| {
        const width = tree_state.width_by_line[line_num];
        if (width > 2) {
            for (1..width - 1) |col| {
                total_positions += 1;
                const cell = tree_state.cells[line_num][col];
                if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                    decoration_count += 1;
                }
            }
        }
    }

    if (total_positions > 0) {
        const actual_density = @as(f32, @floatFromInt(decoration_count)) / @as(f32, @floatFromInt(total_positions));
        // Should be roughly around BASE_DECORATION_DENSITY with some variance
        try expect(actual_density > 0.05 and actual_density < 0.6, "Decoration density {} out of reasonable range", .{actual_density});
    }
}

test "randomization changes at least one decoration" {
    var prng = std.Random.DefaultPrng.init(42);
    var tree_state = tree.TreeState.init();
    tree_state.rng = prng;

    tree_state.generateTree();

    // Use prng to avoid unused warning
    _ = prng.random().uintLessThan(usize, 1);

    // Force all decorations to be unchanged
    for (0..constants.TREE_HEIGHT) |line| {
        for (0..49) |col| {
            tree_state.cells[line][col].changed = false;
        }
    }

    // Randomize decorations
    tree_state.randomizeDecorations();

    // Check that at least one decoration is marked as changed
    var found_changed = false;
    for (0..constants.TREE_HEIGHT) |line| {
        for (0..49) |col| {
            if (tree_state.cells[line][col].changed) {
                found_changed = true;
                break;
            }
        }
        if (found_changed) break;
    }

    try expect(found_changed, "No decorations were marked as changed after randomization");
}

test "tree dimensions match constants" {
    const tree_state = tree.TreeState.init();

    // Check tree height
    try expect(constants.TREE_HEIGHT == 30);
    try expect(constants.TREE_LINES == 25);
    try expect(constants.TRUNK_LINES == 3);

    // Check that trunk appears at the right place
    const trunk_start = constants.TREE_LINES + 1; // line 26
    try expect(trunk_start == 26);

    // Check trunk dimensions
    for (0..constants.TRUNK_LINES) |i| {
        const line_num = trunk_start + i;
        try expect(tree_state.width_by_line[line_num] == constants.TRUNK_WIDTH);
        try expect(constants.TRUNK_WIDTH == 3);
    }
}

test "deterministic generation with fixed seed" {
    var prng1 = std.Random.DefaultPrng.init(12345);
    var tree1 = tree.TreeState.init();
    tree1.rng = prng1;
    tree1.generateTree();

    var prng2 = std.Random.DefaultPrng.init(12345);
    var tree2 = tree.TreeState.init();
    tree2.rng = prng2;
    tree2.generateTree();

    // Use prng variables to avoid unused warnings
    _ = prng1.random().uintLessThan(usize, 1);
    _ = prng2.random().uintLessThan(usize, 1);

    // Trees should be identical when generated with same seed
    try expectEqual(tree1.width_by_line[5], tree2.width_by_line[5]);
    try expectEqual(tree1.cells[5][3].cell_type, tree2.cells[5][3].cell_type);
    try expectEqual(tree1.cells[5][3].color, tree2.cells[5][3].color);
}
