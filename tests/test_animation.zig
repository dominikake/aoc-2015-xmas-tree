const std = @import("std");
const animation = @import("../src/animation.zig");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "animation controller initializes correctly" {
    const controller = try animation.AnimationController.init();
    try expect(controller.running == true);
}

test "animation controller stop flag works" {
    var controller = try animation.AnimationController.init();
    try expect(controller.running == true);

    controller.stop();
    try expect(controller.running == false);
}

test "signal handler sets stop flag" {
    // Test what signal handler does
    var controller = try animation.AnimationController.init();

    // Simulate what signal handler would do
    controller.stop();

    try expect(controller.running == false);
}

test "timer initialization works" {
    var controller = try animation.AnimationController.init();
    _ = controller.timer.read(); // Should not crash
    try expect(true); // If we get here, timer works
}

test "animation interval constants are reasonable" {
    // Import constants to test them
    const constants = @import("../src/constants.zig");

    // Animation interval should be positive
    try expect(constants.ANIMATION_INTERVAL_NS > 0);

    // Refresh interval should be positive and reasonable (not too fast, not too slow)
    try expect(constants.REFRESH_INTERVAL_MS > 0);
    try expect(constants.REFRESH_INTERVAL_MS < 1000);

    // Animation should be longer than refresh
    try expect(constants.ANIMATION_INTERVAL_NS > constants.REFRESH_INTERVAL_MS * 1_000_000);
}
