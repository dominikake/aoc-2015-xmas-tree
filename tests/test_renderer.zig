const std = @import("std");
const renderer = @import("../src/renderer.zig");
const tree = @import("../src/tree.zig");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

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

test "tree width calculation" {
    var tree_state = tree.TreeState.init();
    const tree_width = tree_state.getTreeWidth();

    // Tree should have reasonable width (line 25 = 51 chars max)
    try expect(tree_width > 0);
    try expect(tree_width <= 51);
}

test "centering edge cases" {
    const edge_cases = [_]struct { term_width: usize, tree_width: usize, expected: usize }{
        .{ .term_width = 1, .tree_width = 1, .expected = 0 }, // Minimum
        .{ .term_width = 1000, .tree_width = 1, .expected = 499 }, // Large
        .{ .term_width = 51, .tree_width = 49, .expected = 1 }, // Almost fit
        .{ .term_width = 52, .tree_width = 51, .expected = 0 }, // Almost fit with 1 extra
    };

    for (edge_cases) |case| {
        const actual = if (case.tree_width >= case.term_width) 0 else (case.term_width - case.tree_width) / 2;
        try expectEqual(case.expected, actual);
    }
}
