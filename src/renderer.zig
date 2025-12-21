const std = @import("std");
const c_sysioctl = @cImport(@cInclude("sys/ioctl.h"));
const c_ioctl = @cImport(@cInclude("ioctl.h"));
const tree = @import("tree.zig");
const colors = @import("colors.zig");
const constants = @import("constants.zig");

pub const SimpleRenderer = struct {
    writer: std.fs.File.Writer,
    file: std.fs.File,

    pub fn init(file: std.fs.File, writer: std.fs.File.Writer) SimpleRenderer {
        return SimpleRenderer{
            .file = file,
            .writer = writer,
        };
    }

    pub fn clearScreen(self: SimpleRenderer) !void {
        try self.file.writeAll("\x1b[2J\x1b[H");
    }

    pub fn hideCursor(self: SimpleRenderer) !void {
        try self.file.writeAll("\x1b[?25l");
    }

    pub fn showCursor(self: SimpleRenderer) !void {
        try self.file.writeAll("\x1b[?25h");
    }

    pub fn calculateCenterOffset(self: SimpleRenderer, tree_state: tree.TreeState) usize {
        _ = self; // Suppress unused warning
        const tree_width = tree_state.getTreeWidth();
        // Calculate max width based on tree geometry (line 25 = 51 chars)
        const max_width = (constants.TREE_LINES * 2) + 1;
        // Calculate center spaces: (max_width - current_width) / 2
        const center_spaces = (max_width - tree_width) / 2;
        return center_spaces;
    }

    fn getTerminalWidth() usize {
        // Fallback to 80 for simplicity
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
                try self.file.writeAll("\n");
                continue;
            }

            // Add centering spaces
            for (0..center_offset) |_| {
                try self.file.writeAll(" ");
            }

            // Render each character in line
            for (0..width) |col| {
                const cell = tree_state.cells[line][col];
                if (cell.char != ' ') {
                    try colors.applyColor(self.file, cell.color);
                    try self.file.writeAll(&[_]u8{cell.char});
                    try colors.resetColor(self.file);
                } else {
                    try self.file.writeAll(" ");
                }
            }

            try self.file.writeAll("\n");
        }
    }

    pub fn renderTreeFast(self: *SimpleRenderer, tree_state: tree.TreeState) !void {
        _ = self;
        _ = tree_state;
        // For now, just use the full render method
        // TODO: Implement differential rendering for performance
    }
};
