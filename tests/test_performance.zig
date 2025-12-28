const std = @import("std");
const renderer = @import("../src/renderer.zig");
const tree = @import("../src/tree.zig");
const animation = @import("../src/animation.zig");
const constants = @import("../src/constants.zig");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "rendering performance under 100ms" {
    var controller = try animation.AnimationController.init();
    const start = std.time.nanoTimestamp();

    // Time a single render
    try controller.terminal_renderer.renderTree(controller.tree_state);

    const end = std.time.nanoTimestamp();
    const duration_ms = @as(u64, @intCast(end - start)) / 1_000_000;
    try expect(duration_ms < 100, "Rendering took {}ms, expected < 100ms", .{duration_ms});
}

test "differential rendering performance" {
    var controller = try animation.AnimationController.init();

    // Time a differential render (should be faster when no changes)
    const start1 = std.time.nanoTimestamp();
    try controller.terminal_renderer.renderTree(controller.tree_state);
    const end1 = std.time.nanoTimestamp();

    // Force no changes
    for (0..constants.TREE_HEIGHT) |line| {
        for (0..49) |col| {
            controller.tree_state.cells[line][col].changed = false;
        }
    }

    // Time second render with no changes
    const start2 = std.time.nanoTimestamp();
    try controller.terminal_renderer.renderTree(controller.tree_state);
    const end2 = std.time.nanoTimestamp();

    const duration1_ms = @as(u64, @intCast(end1 - start1)) / 1_000_000;
    const duration2_ms = @as(u64, @intCast(end2 - start2)) / 1_000_000;

    // Second render should be faster (or at least not much slower)
    try expect(duration2_ms <= duration1_ms + 10, "Differential render was slower than full render");
}

test "frame pacing prevents excessive renders" {
    // Test that refresh interval is reasonable for frame pacing
    try expect(constants.REFRESH_INTERVAL_MS >= 16, "Refresh interval too fast (< 60 FPS)");
    try expect(constants.REFRESH_INTERVAL_MS <= 100, "Refresh interval too slow (< 10 FPS)");

    // Test that animation interval is much longer than refresh
    const animation_to_refresh_ratio = constants.ANIMATION_INTERVAL_NS / (constants.REFRESH_INTERVAL_MS * 1_000_000);
    try expect(animation_to_refresh_ratio >= 10, "Animation should happen much less frequently than refresh");
}

test "tree generation performance" {
    const start = std.time.nanoTimestamp();

    // Generate multiple trees to test performance
    for (0..10) |_| {
        const tree_state = tree.TreeState.init();
        _ = tree_state.getTreeWidth(); // Access tree data
    }

    const end = std.time.nanoTimestamp();
    const avg_duration_ms = (@as(u64, @intCast(end - start)) / 1_000_000) / 10;

    try expect(avg_duration_ms < 50, "Tree generation took too long: {}ms per tree", .{avg_duration_ms});
}

test "centering calculation performance" {
    const tree_state = tree.TreeState.init();
    const tree_width = tree_state.getTreeWidth();

    const start = std.time.nanoTimestamp();

    // Test centering calculation multiple times
    for (0..1000) |i| {
        const term_width = 80 + (i % 40); // Vary terminal width
        _ = if (tree_width >= term_width) 0 else (term_width - tree_width) / 2;
    }

    const end = std.time.nanoTimestamp();
    const total_duration_ms = @as(u64, @intCast(end - start)) / 1_000_000;

    try expect(total_duration_ms < 10, "Centering calculation took too long: {}ms", .{total_duration_ms});
}
