const std = @import("std");
const tree = @import("tree.zig");
const colors = @import("colors.zig");
const constants = @import("constants.zig");

// Terminal size structure for TIOCGWINSZ ioctl
const winsize = extern struct {
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
};

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

    pub fn calculateCenterOffset(_: SimpleRenderer, tree_state: tree.TreeState) usize {
        const tree_width = tree_state.getTreeWidth();
        const term_width = getTerminalWidth();

        // If tree is wider than terminal, no centering possible
        if (tree_width >= term_width) {
            return 0;
        }

        // Calculate center offset: (terminal_width - tree_width) / 2
        const center_offset = (term_width - tree_width) / 2;
        return center_offset;
    }

    fn getTerminalWidth() usize {
        // Try to get terminal width using environment variable fallback for now
        // In Zig 0.15.2, direct ioctl without C imports is complex
        // Use COLUMNS environment variable if available, otherwise fallback
        if (std.posix.getenv("COLUMNS")) |columns_str| {
            if (std.fmt.parseInt(usize, columns_str, 10)) |columns| {
                if (columns > 0) return columns;
            } else |_| {}
        }

        // Try tput command as fallback (may fail, that's ok)
        const result = std.process.Child.run(.{
            .allocator = std.heap.page_allocator,
            .argv = &[_][]const u8{ "tput", "cols" },
        }) catch return 80;

        if (result.term.Exited == 0) {
            if (std.fmt.parseInt(usize, std.mem.trim(u8, result.stdout, " \n\r\t"), 10)) |cols| {
                if (cols > 0) return cols;
            } else |_| {}
        }

        // Final fallback
        return 80;
    }

    fn calculateLineOffset(terminal_width: usize, max_tree_width: usize, line: usize) usize {
        const terminal_offset = if (max_tree_width >= terminal_width) 0 else (terminal_width - max_tree_width) / 2;

        const triangle_offset = if (line == 0) constants.TREE_LINES // star line gets max offset
        else if (line <= constants.TREE_LINES) constants.TREE_LINES - line // tree lines get progressively less offset
        else constants.TREE_LINES - constants.TRUNK_LINES; // trunk lines get constant offset to stay centered

        return terminal_offset + triangle_offset;
    }

    pub fn renderTree(self: *SimpleRenderer, tree_state: *tree.TreeState) !void {
        const terminal_width = getTerminalWidth();
        const max_tree_width = tree_state.getTreeWidth();
        var has_changes = false;

        // Check if any cells changed
        for (0..constants.TREE_HEIGHT) |line| {
            const width = tree_state.width_by_line[line];
            for (0..width) |col| {
                if (tree_state.cells[line][col].changed) {
                    has_changes = true;
                    break;
                }
            }
            if (has_changes) break;
        }

        // Only clear and re-render if there are changes
        if (has_changes) {
            try self.clearScreen();

            // Render each line with triangular centering
            for (0..constants.TREE_HEIGHT) |line| {
                const width = tree_state.width_by_line[line];
                if (width == 0) {
                    // Empty line
                    try self.file.writeAll("\n");
                    continue;
                }

                // Calculate line-specific centering for triangular shape
                const line_offset = calculateLineOffset(terminal_width, max_tree_width, line);

                // Add centering spaces
                for (0..line_offset) |_| {
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

            // Reset changed flags after successful render
            for (0..constants.TREE_HEIGHT) |line| {
                const width = tree_state.width_by_line[line];
                for (0..width) |col| {
                    tree_state.cells[line][col].changed = false;
                }
            }
        }
    }

    pub fn renderTreeFast(self: *SimpleRenderer, tree_state: *tree.TreeState) !void {
        const terminal_width = getTerminalWidth();
        const max_tree_width = tree_state.getTreeWidth();
        var has_changes = false;

        // Check if any cells changed
        for (0..constants.TREE_HEIGHT) |line| {
            const width = tree_state.width_by_line[line];
            for (0..width) |col| {
                if (tree_state.cells[line][col].changed) {
                    has_changes = true;
                    break;
                }
            }
            if (has_changes) break;
        }

        // Only re-render if there are changes
        if (has_changes) {
            // Use cursor positioning for differential update
            try self.file.writeAll("\x1b[H"); // Move cursor to top-left

            // Render only changed lines with triangular centering
            for (0..constants.TREE_HEIGHT) |line| {
                const width = tree_state.width_by_line[line];
                var line_has_changes = false;

                // Check if this line has any changes
                for (0..width) |col| {
                    if (tree_state.cells[line][col].changed) {
                        line_has_changes = true;
                        break;
                    }
                }

                if (line_has_changes) {
                    // Calculate line-specific centering for triangular shape
                    const line_offset = calculateLineOffset(terminal_width, max_tree_width, line);

                    // Add centering spaces
                    for (0..line_offset) |_| {
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
                }

                try self.file.writeAll("\n");
            }
        }
    }
};
