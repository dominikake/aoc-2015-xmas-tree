const std = @import("std");
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
            .cells = std.mem.zeroes([constants.TREE_HEIGHT][49]TreeCell),
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

        // Line 0: Star (centered)
        const star_line: usize = 0;
        self.width_by_line[star_line] = 1;
        self.cells[star_line][0] = TreeCell{
            .char = constants.STAR_CHAR,
            .color = colors.AnsiColor.yellow,
            .cell_type = constants.CellType.star,
            .changed = true,
        };

        // Lines 1-24: Tree body (start at line 1, width starts at 3 and increments by 2)
        for (1..constants.TREE_LINES + 1) |i| {
            const line_num: usize = i; // 1 to 24
            const width: usize = (line_num + 1) * 2 - 1; // 3, 5, 7, 9, 11...
            self.width_by_line[line_num] = width;

            // Left foliage
            self.cells[line_num][0] = TreeCell{
                .char = constants.FOLIAGE_LEFT,
                .color = colors.AnsiColor.bright_green,
                .cell_type = constants.CellType.foliage,
                .changed = true,
            };

            // Right foliage
            self.cells[line_num][width - 1] = TreeCell{
                .char = constants.FOLIAGE_RIGHT,
                .color = colors.AnsiColor.bright_green,
                .cell_type = constants.CellType.foliage,
                .changed = true,
            };

            // Interior positions (between foliage)
            if (width > 2) {
                // Calculate line-specific decoration density
                const line_density = constants.BASE_DECORATION_DENSITY +
                    (self.rng.random().float(f32) - 0.5) * constants.DENSITY_VARIANCE * 2;
                const clamped_density = @max(0.1, @min(0.5, line_density));

                var prev_was_decoration = false;

                for (1..width - 1) |col| {
                    // 30% fixed ornaments, 70% animated
                    const is_fixed = self.rng.random().float(f32) < 0.3;

                    // Check if this should be a decoration based on density and spacing rules
                    const density_roll = self.rng.random().float(f32);
                    // Rule: No two ornaments adjacent, always leave at least one space/foliage between
                    const can_be_decoration = !prev_was_decoration and !is_fixed and
                        (density_roll < clamped_density);

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

                    // Track decoration placement - ensure spacing between ornaments
                    if (can_be_decoration) {
                        prev_was_decoration = true;
                    } else {
                        prev_was_decoration = false;
                    }
                }
            }
        }

        // Lines 25-27: Trunk (3 lines)
        const trunk_start = constants.TREE_LINES + 1; // line 25
        // Center the trunk under the tree: bottom line center is 24, trunk offset makes effective center at 3
        const trunk_start_col = 2;
        for (0..constants.TRUNK_LINES) |i| {
            const line_num = trunk_start + i;
            self.width_by_line[line_num] = trunk_start_col + constants.TRUNK_WIDTH;

            for (0..constants.TRUNK_WIDTH) |col| {
                self.cells[line_num][trunk_start_col + col] = TreeCell{
                    .char = constants.TRUNK_CHAR,
                    .color = colors.AnsiColor.white,
                    .cell_type = constants.CellType.trunk,
                    .changed = true,
                };
            }
        }

        // Line 28: Empty
        self.width_by_line[constants.TREE_HEIGHT - 1] = 0;
    }

    pub fn randomizeDecorations(self: *TreeState) void {
        var any_changed = false;

        // Randomize only ornaments and lights, not foliage
        for (1..constants.TREE_LINES + 1) |line_num| {
            const width = self.width_by_line[line_num];
            if (width > 2) {
                var prev_was_decoration = false;

                for (1..width - 1) |col| {
                    var cell = &self.cells[line_num][col];

                    // Check both current and next/previous cells to maintain spacing
                    const is_decoration = cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light;

                    if (is_decoration) {
                        const stability: f32 = if (cell.cell_type == constants.CellType.ornament) constants.ORNAMENT_STABILITY else constants.LIGHT_STABILITY;
                        const rand_val = self.rng.random().float(f32);

                        // Apply spacing rules: only change if won't create adjacent decorations
                        const should_change = rand_val > stability and !prev_was_decoration;

                        // Check next cell if it exists
                        var next_will_be_decoration = false;
                        if (col < width - 2) {
                            const next_cell = &self.cells[line_num][col + 1];
                            next_will_be_decoration = next_cell.cell_type == constants.CellType.ornament or next_cell.cell_type == constants.CellType.light;
                        }

                        if (should_change and !next_will_be_decoration) {
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
                                .is_fixed = false,
                            };

                            any_changed = true;
                            prev_was_decoration = true;
                        } else {
                            cell.changed = false;
                            prev_was_decoration = false;
                        }
                    } else {
                        // Non-decoration cell - could become decoration
                        cell.changed = false;
                        prev_was_decoration = false;
                    }
                }
            }
        }

        // If nothing changed, mark one random decoration as changed to prevent animation stalling
        if (!any_changed) {
            self.markOneRandomDecorationChanged();
        }
    }

    fn markOneRandomDecorationChanged(self: *TreeState) void {
        // Count total decorations first
        var decoration_count: usize = 0;
        for (1..constants.TREE_LINES + 1) |line_num| {
            const width = self.width_by_line[line_num];
            if (width > 2) {
                for (1..width - 1) |col| {
                    const cell = self.cells[line_num][col];
                    if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                        decoration_count += 1;
                    }
                }
            }
        }

        // Pick a random decoration index and find it
        if (decoration_count > 0) {
            const target_index = self.rng.random().uintLessThan(usize, decoration_count);
            var current_index: usize = 0;

            for (1..constants.TREE_LINES + 1) |line_num| {
                const width = self.width_by_line[line_num];
                if (width > 2) {
                    for (1..width - 1) |col| {
                        const cell = self.cells[line_num][col];
                        if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                            if (current_index == target_index) {
                                self.cells[line_num][col].changed = true;
                                return;
                            }
                            current_index += 1;
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
