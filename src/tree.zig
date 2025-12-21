const std = @import("std");
const c = @cImport(@cInclude("signal.h"));
const constants = @import("constants.zig");
const colors = @import("colors.zig");

pub const TreeCell = struct {
    char: u8,
    color: colors.AnsiColor,
    cell_type: constants.CellType,
    changed: bool = false,
    is_fixed: bool = false,
};

pub const TreeState = struct {
    cells: [constants.TREE_HEIGHT][49]TreeCell, // 30 lines, max 49 chars for line 25
    width_by_line: [constants.TREE_HEIGHT]usize,
    center_offset: usize,
    rng: std.Random.DefaultPrng,

    pub fn init() TreeState {
        const seed: u64 = @intCast(std.time.timestamp());
        const prng = std.Random.DefaultPrng.init(seed);
        var tree = TreeState{
            .cells = std.mem.zeroes([constants.TREE_HEIGHT][51]TreeCell),
            .width_by_line = std.mem.zeroes([constants.TREE_HEIGHT]usize),
            .center_offset = 0,
            .rng = prng,
        };

        tree.generateTree();
        return tree;
    }

    fn generateTree(self: *TreeState) void {
        // Clear all cells first
        for (0..constants.TREE_HEIGHT) |line| {
            self.width_by_line[line] = 0;
            for (0..49) |col| {
                self.cells[line][col] = TreeCell{
                    .char = ' ',
                    .color = colors.AnsiColor.reset,
                    .cell_type = constants.CellType.trunk, // default
                    .changed = false,
                };
            }
        }
        }

        // Line 0: Star (centered)
        const star_line: usize = 0;
        self.width_by_line[star_line] = 1;
        self.cells[star_line][0] = TreeCell{
            .char = constants.STAR_CHAR,
            .color = colors.AnsiColor.yellow,
            .cell_type = constants.CellType.star,
            .changed = true,
        };

        // Lines 1-25: Tree body (start at line 1, but width starts at 3)
        for (1..constants.TREE_LINES + 1) |i| {
            const line_num: usize = i; // 1 to 25
            const width: usize = if (line_num == 0) 1 else (line_num * 2) - 1; // 1, 3, 5, 7, 9...
            self.width_by_line[line_num] = width;

            // Left foliage
            self.cells[line_num][0] = TreeCell{
                .char = constants.FOLIAGE_LEFT,
                .color = colors.AnsiColor.green,
                .cell_type = constants.CellType.foliage,
                .changed = true,
            };

            // Right foliage
            self.cells[line_num][width - 1] = TreeCell{
                .char = constants.FOLIAGE_RIGHT,
                .color = colors.AnsiColor.green,
                .cell_type = constants.CellType.foliage,
                .changed = true,
            };

            // Interior positions (between foliage)
            if (width > 2) {
                var prev_was_decoration = false;
                for (1..width - 1) |col| {
                    // 30% fixed ornaments, 70% animated
                    const is_fixed = self.rng.random().float(f32) < 0.3;
                    const can_be_decoration = !prev_was_decoration and !is_fixed;
                    const cell_type = if (can_be_decoration) constants.CellType.light else constants.CellType.ornament;
                    const char = if (cell_type == .light) constants.LIGHT_CHAR else constants.ORNAMENT_CHARS[self.rng.random().uintLessThan(usize, constants.ORNAMENT_CHARS.len)];
                    const color = colors.getRandomColorForCell(cell_type, self.rng.random());

                    self.cells[line_num][col] = TreeCell{
                        .char = char,
                        .color = color,
                        .cell_type = cell_type,
                        .changed = true,
                        .is_fixed = is_fixed,
                    };
                    
                    // Track if this position was a decoration for next iteration
                    prev_was_decoration = (cell_type == .light or cell_type == .ornament);
                }
            }
        }

        // Lines 26-28: Trunk (3 lines)
        const trunk_start = constants.TREE_LINES + 1; // line 26
        for (0..constants.TRUNK_LINES) |i| {
            const line_num = trunk_start + i;
            self.width_by_line[line_num] = constants.TRUNK_WIDTH;

            for (0..constants.TRUNK_WIDTH) |col| {
                self.cells[line_num][col] = TreeCell{
                    .char = constants.TRUNK_CHAR,
                    .color = colors.AnsiColor.white,
                    .cell_type = constants.CellType.trunk,
                    .changed = true,
                };
            }
        }

        // Line 29: Empty
        self.width_by_line[constants.TREE_HEIGHT - 1] = 0;
    }

    pub fn randomizeDecorations(self: *TreeState) void {
        // Randomize only ornaments and lights, not foliage
        for (1..constants.TREE_LINES + 1) |line_num| {
            const width = self.width_by_line[line_num];
            if (width > 2) {
                for (1..width - 1) |col| {
                    var cell = &self.cells[line_num][col];
                    if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                        const stability: f32 = if (cell.cell_type == constants.CellType.ornament) constants.ORNAMENT_STABILITY else constants.LIGHT_STABILITY;

                        if (self.rng.random().float(f32) > stability) {
                            // Change this cell
                            const is_light = self.rng.random().float(f32) < 0.4;
                            const new_type = if (is_light) constants.CellType.light else constants.CellType.ornament;
                            const new_char = if (is_light) constants.LIGHT_CHAR else constants.ORNAMENT_CHARS[self.rng.random().uintLessThan(usize, constants.ORNAMENT_CHARS.len)];
                            const new_color = colors.getRandomColorForCell(new_type, self.rng.random());

                            cell.* = TreeCell{
                                .char = new_char,
                                .color = new_color,
                                .cell_type = new_type,
                                .changed = true,
                            };
                        } else {
                            cell.changed = false;
                        }
                    }
                }
            }
        }
    }

    pub fn getTreeWidth(self: *const TreeState) usize {
        var max_width: usize = 0;
        for (self.width_by_line) |width| {
            if (width > max_width) max_width = width;
        }
        return max_width;
    }
};
