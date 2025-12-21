const std = @import("std");
const tree = @import("tree.zig");
const colors = @import("colors.zig");
const constants = @import("constants.zig");

pub const SimpleRenderer = struct {
    writer: std.fs.File.Writer,

    pub fn init(file_writer: std.fs.File.Writer) SimpleRenderer {
        return SimpleRenderer{
            .writer = file_writer,
        };
    }

    pub fn clearScreen(self: SimpleRenderer) !void {
        try self.writer.writeAll("\x1b[2J\x1b[H");
    }

    pub fn hideCursor(self: SimpleRenderer) !void {
        try self.writer.writeAll("\x1b[?25l");
    }

    pub fn showCursor(self: SimpleRenderer) !void {
        try self.writer.writeAll("\x1b[?25h");
        try self.writer.flush();
    }

    pub fn calculateCenterOffset(self: SimpleRenderer, tree_state: tree.TreeState) usize {
        _ = self; // Suppress unused warning
        const tree_width = tree_state.getTreeWidth();
        // Get terminal width (default to 80 if we can't detect)
        const term_width = getTerminalWidth();
        if (tree_width >= term_width) return 0;
        return (term_width - tree_width) / 2;
    }

    fn getTerminalWidth() usize {
        // Try to get terminal width, fallback to 80
        var ws: std.os.winsize = undefined;
        if (std.io.getStdErr().isTty()) {
            if (std.os.ioctl(std.io.getStdErr().handle, std.os.T.IOCGWINSZ, @intFromPtr(&ws)) == 0) {
                return ws.ws_col;
            }
        }
        return 80;
    }

    pub fn renderTree(self: *SimpleRenderer, tree_state: tree.TreeState) !void {
        const center_offset = self.calculateCenterOffset(tree_state);

        // Clear screen
        try self.clearScreen();

        // Render each line
        for (0..constants.TREE_HEIGHT) |line| {
            const width = tree_state.width_by_line[line];
            if (width == 0) {
                // Empty line
                try self.writer.writeAll("\n");
                continue;
            }

            // Add centering spaces
            for (0..center_offset) |_| {
                try self.writer.writeByte(' ');
            }

            // Render each character in line
            for (0..width) |col| {
                const cell = tree_state.cells[line][col];
                if (cell.char != ' ') {
                    try colors.applyColor(self.writer, cell.color);
                    try self.writer.writeByte(cell.char);
                    try colors.resetColor(self.writer);
                } else {
                    try self.writer.writeByte(' ');
                }
            }

            try self.writer.writeAll("\n");
        }

        try self.writer.flush();
    }

    pub fn renderTreeFast(self: *SimpleRenderer, tree_state: tree.TreeState) !void {
        _ = self;
        _ = tree_state;
        // For now, just use the full render method
        // TODO: Implement differential rendering for performance
    }
};
