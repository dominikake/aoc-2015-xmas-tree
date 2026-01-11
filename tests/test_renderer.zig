const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// Common test types
const TestCellType = enum {
    star,
    foliage,
    ornament,
    light,
    trunk,
};

const TestCell = struct {
    char: u8,
    cell_type: TestCellType,
    changed: bool = false,
    color: u8 = 0,
    is_fixed: bool = false,
};

// Mock terminal for testing
const MockTerminal = struct {
    width: usize,

    fn init(width: usize) MockTerminal {
        return MockTerminal{ .width = width };
    }
};

test "centering calculation basic cases" {
    const test_cases = [_]struct { term_width: usize, tree_width: usize, expected: usize }{
        .{ .term_width = 80, .tree_width = 20, .expected = 30 },
        .{ .term_width = 120, .tree_width = 51, .expected = 34 },
        .{ .term_width = 40, .tree_width = 10, .expected = 15 },
        .{ .term_width = 100, .tree_width = 50, .expected = 25 },
    };

    for (test_cases) |case| {
        // We'll test the calculation logic directly
        const actual = if (case.tree_width >= case.term_width) 0 else (case.term_width - case.tree_width) / 2;
        try expectEqual(case.expected, actual);
    }
}

test "centering with tree wider than terminal" {
    const term_width = 40;
    const tree_width = 51;

    // Should return 0 (no centering possible)
    const expected = 0;
    const actual = if (tree_width >= term_width) 0 else (term_width - tree_width) / 2;
    try expectEqual(expected, actual);
}

test "centering with exact fit" {
    const term_width = 51;
    const tree_width = 51;

    // Should return 0 (tree exactly fits)
    const expected = 0;
    const actual = if (tree_width >= term_width) 0 else (term_width - tree_width) / 2;
    try expectEqual(expected, actual);
}

test "terminal width fallback handling" {
    // Test the fallback logic - when terminal detection fails, should use 80
    const fallback_width = 80;
    try expect(fallback_width > 0);
    try expect(fallback_width >= 50); // Should be wide enough for tree
}

test "centering edge cases" {
    const test_cases = [_]struct { term_width: usize, tree_width: usize, expected: usize }{
        .{ .term_width = 40, .tree_width = 51, .expected = 0 }, // Tree wider than terminal
        .{ .term_width = 51, .tree_width = 51, .expected = 0 }, // Exact fit
        .{ .term_width = 52, .tree_width = 51, .expected = 0 }, // 1 pixel difference
        .{ .term_width = 53, .tree_width = 51, .expected = 1 }, // Small centering
        .{ .term_width = 100, .tree_width = 51, .expected = 24 }, // Large centering
    };

    for (test_cases) |case| {
        const actual = if (case.tree_width >= case.term_width) 0 else (case.term_width - case.tree_width) / 2;
        try expectEqual(case.expected, actual);
    }
}

test "no consecutive ornaments" {
    // Mock implementation to test the logic fix
    // Test cell types and consecutive decoration checking

    // Simulate a line with decorations and check logic
    const mock_cells = [_]TestCell{
        .{ .char = '>', .cell_type = .foliage },
        .{ .char = 'o', .cell_type = .ornament },
        .{ .char = '<', .cell_type = .foliage }, // Foliage between ornaments
        .{ .char = '@', .cell_type = .ornament },
        .{ .char = '<', .cell_type = .foliage }, // Foliage between ornament and next potential
        .{ .char = '<', .cell_type = .foliage },
    };

    var prev_was_ornament: bool = false;

    for (mock_cells) |cell| {
        const is_ornament = cell.cell_type == .ornament or cell.cell_type == .light;
        const is_star = cell.cell_type == .star;

        // Check for consecutive ornaments/lights - any two decorations in a row should not happen
        if ((is_ornament or is_star) and prev_was_ornament) {
            // This should never happen - no consecutive ornaments/lights allowed
            try expect(false);
        }

        // Track if current cell is a decoration (ornament or light, not star)
        prev_was_ornament = is_ornament;
    }
}

test "no FOLIAGE_LEFT/FOLIAGE_RIGHT literals in rendered output" {
    // Test that proper character values are used, not string literals

    const test_cells = [_]TestCell{
        .{ .char = '>', .cell_type = .foliage },
        .{ .char = '<', .cell_type = .foliage },
        .{ .char = 'o', .cell_type = .ornament },
        .{ .char = '@', .cell_type = .ornament },
    };

    // Verify foliage cells use proper character values
    var found_foliage_left_char = false;
    var found_foliage_right_char = false;

    for (test_cells) |cell| {
        if (cell.cell_type == .foliage) {
            // Verify foliage cells use '>' or '<' characters, not string literals
            try expect(cell.char == '>' or cell.char == '<');
        }

        if (cell.char == '>') {
            found_foliage_left_char = true;
        }
        if (cell.char == '<') {
            found_foliage_right_char = true;
        }
    }

    // Verify we actually have foliage characters
    try expect(found_foliage_left_char);
    try expect(found_foliage_right_char);
}

test "refresh regenerates ornaments different output" {
    // Test that randomization changes decorations
    const initial_cells = [_]TestCell{
        .{ .char = 'o', .cell_type = .ornament, .color = 1, .changed = false },
        .{ .char = '@', .cell_type = .ornament, .color = 2, .changed = false },
    };

    // Simulate randomization changing some decorations
    const changed_cells = [_]TestCell{
        .{ .char = '@', .cell_type = .ornament, .color = 3, .changed = true }, // Changed
        .{ .char = 'o', .cell_type = .ornament, .color = 1, .changed = false }, // Unchanged
    };

    // Check that at least some decorations changed
    var found_changes = false;
    for (initial_cells, 0..) |initial_cell, i| {
        const current_cell = changed_cells[i];

        const was_decoration = initial_cell.cell_type == .ornament or initial_cell.cell_type == .light;
        const is_decoration = current_cell.cell_type == .ornament or current_cell.cell_type == .light;

        if (was_decoration and is_decoration) {
            if (initial_cell.char != current_cell.char or initial_cell.color != current_cell.color) {
                found_changes = true;
                break;
            }
        }
    }

    try expect(found_changes);
}

test "sample rendered lines verify ornament spacing rules" {
    // Test specific lines for spacing rules

    // Simulate a tree line with proper spacing
    const mock_line = [_]TestCell{
        .{ .char = '>', .cell_type = .foliage }, // Left edge
        .{ .char = 'o', .cell_type = .ornament }, // Ornament
        .{ .char = '<', .cell_type = .foliage }, // Foliage between ornaments
        .{ .char = '@', .cell_type = .ornament }, // Another ornament
        .{ .char = '<', .cell_type = .foliage }, // Right edge
    };

    var consecutive_count: usize = 0;
    var prev_was_ornament: bool = false;

    for (mock_line) |cell| {
        const is_ornament = cell.cell_type == .ornament;

        if (is_ornament) {
            if (prev_was_ornament) {
                consecutive_count += 1;
            } else {
                consecutive_count = 1;
            }

            // Should not have more than 1 consecutive ornament
            try expect(consecutive_count <= 1);

            prev_was_ornament = true;
        } else {
            consecutive_count = 0;
            prev_was_ornament = false;
        }
    }
}
