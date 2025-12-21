const std = @import("std");
const tree = @import("tree.zig");
const renderer = @import("renderer.zig");
const constants = @import("constants.zig");

pub const AnimationController = struct {
    timer: std.time.Timer,
    last_randomization: u64 = 0,
    tree_state: tree.TreeState,
    terminal_renderer: renderer.SimpleRenderer,
    running: bool = true,

    pub fn init() !AnimationController {
        var timer = try std.time.Timer.start();
        var tree_state = tree.TreeState.init();
        const stdout_file = std.fs.File.stdout();
        var writer_buffer: [4096]u8 = undefined;
        var terminal_renderer = renderer.SimpleRenderer.init(stdout_file, stdout_file.writer(&writer_buffer));

        _ = &timer; // Suppress unused warnings
        _ = &tree_state;
        _ = &terminal_renderer;

        return AnimationController{
            .timer = timer,
            .tree_state = tree_state,
            .terminal_renderer = terminal_renderer,
        };
    }

    pub fn run(self: *AnimationController) !void {
        // Setup terminal
        try self.terminal_renderer.hideCursor();
        defer self.terminal_renderer.showCursor() catch {};

        // Initial render
        try self.terminal_renderer.renderTree(self.tree_state);

        while (self.running) {
            const current_time = self.timer.read();

            // Check if it's time to randomize (every 2.5 seconds)
            if (current_time - self.last_randomization >= constants.ANIMATION_INTERVAL_NS) {
                self.tree_state.randomizeDecorations();
                self.last_randomization = current_time;
            }

            // Render current state
            try self.terminal_renderer.renderTree(self.tree_state);

            // Sleep to prevent excessive CPU usage
            std.posix.nanosleep(0, constants.REFRESH_INTERVAL_MS * 1_000_000);
        }
    }

    pub fn stop(self: *AnimationController) void {
        self.running = false;
    }
};
