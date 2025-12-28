const std = @import("std");
const animation = @import("animation.zig");

// Global animation controller for signal handling
var animation_controller: ?*animation.AnimationController = null;

fn signalHandler(sig: c_int) callconv(.c) void {
    _ = sig;
    if (animation_controller) |controller| {
        controller.stop();
    }
}

pub fn main() !void {
    // Initialize animation controller
    var controller = try animation.AnimationController.init();
    animation_controller = &controller;

    // Set up signal handling for Ctrl+C
    const sigact = std.posix.Sigaction{
        .handler = .{ .handler = signalHandler },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };

    std.posix.sigaction(std.posix.SIG.INT, &sigact, null);

    // Run the animation
    try controller.run();
}
