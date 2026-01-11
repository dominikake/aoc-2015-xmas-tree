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

                var prev_was_ornament: bool = false;

                for (1..width - 1) |col| {
                    // 30% fixed ornaments, 70% animated
                    const is_fixed = self.rng.random().float(f32) < 0.3;

                    // Check if previous was an ornament
                    const prev_orn = prev_was_ornament;

                    // Check if this should be a decoration based on density and spacing rules
                    // Rule: No two ornaments adjacent, always leave at least one foliage between
                    const density_roll = self.rng.random().float(f32);
                    const can_be_decoration = !prev_orn and !is_fixed and
                        (density_roll < clamped_density);

                    const cell_type = if (can_be_decoration)
                        if (self.rng.random().float(f32) < 0.4) constants.CellType.light else constants.CellType.ornament
                    else
                        constants.CellType.foliage;

                    // Generate character
                    var char: u8 = undefined;
                    if (cell_type == .light) {
                        char = constants.LIGHT_CHAR;
                    } else if (cell_type == .ornament) {
                        // Can place ornament
                        char = constants.ORNAMENT_CHARS[self.rng.random().uintLessThan(usize, constants.ORNAMENT_CHARS.len)];
                    } else {
                        // Foliage - use random foliage character
                        char = if (self.rng.random().uintLessThan(u8, 2) == 1) constants.FOLIAGE_LEFT else constants.FOLIAGE_RIGHT;
                    }

                    const color = colors.getRandomColorForCell(cell_type, self.rng.random());

                    self.cells[line_num][col] = TreeCell{
                        .char = char,
                        .color = color,
                        .cell_type = cell_type,
                        .changed = true,
                        .is_fixed = is_fixed,
                    };

                    // Track for next iteration
                    prev_was_ornament = (cell_type == constants.CellType.ornament);
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

    fn ensureMinimumOrnaments(self: *TreeState, line_num: usize, width: usize) void {
        if (width <= 2) return; // No interior positions

        // Calculate minimum ornaments needed: at least 1 per 3 characters of interior space
        const interior_space = width - 2; // Excluding left and right foliage
        const minimum_ornaments = @max(1, interior_space / 3);

        // Count current ornaments and lights on this line
        var current_ornaments: usize = 0;

        for (1..width - 1) |col| {
            const cell = self.cells[line_num][col];
            if (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light) {
                current_ornaments += 1;
            }
        }

        // If we already have enough ornaments, return
        if (current_ornaments >= minimum_ornaments) return;

        // Need to add more ornaments
        const ornaments_to_add = minimum_ornaments - current_ornaments;
        var added: usize = 0;

        // Try to add ornaments at valid positions (not adjacent to other ornaments)
        for (1..width - 1) |col| {
            if (added >= ornaments_to_add) break;

            const cell = self.cells[line_num][col];
            // Only consider foliage positions (non-ornaments)
            if (cell.cell_type == constants.CellType.foliage) {
                // Check if this position is valid (not adjacent to existing ornaments)
                var can_place = true;

                // Check left neighbor
                if (col > 1) {
                    const left_cell = self.cells[line_num][col - 1];
                    if (left_cell.cell_type == constants.CellType.ornament or left_cell.cell_type == constants.CellType.light) {
                        can_place = false;
                    }
                }

                // Check right neighbor
                if (col < width - 2 and can_place) {
                    const right_cell = self.cells[line_num][col + 1];
                    if (right_cell.cell_type == constants.CellType.ornament or right_cell.cell_type == constants.CellType.light) {
                        can_place = false;
                    }
                }

                if (can_place) {
                    // Add an ornament here
                    const is_light = self.rng.random().float(f32) < 0.4;
                    const new_type = if (is_light) constants.CellType.light else constants.CellType.ornament;
                    const new_char = if (is_light) constants.LIGHT_CHAR else constants.ORNAMENT_CHARS[self.rng.random().uintLessThan(usize, constants.ORNAMENT_CHARS.len)];
                    const new_color = colors.getRandomColorForCell(new_type, self.rng.random());

                    self.cells[line_num][col] = TreeCell{
                        .char = new_char,
                        .color = new_color,
                        .cell_type = new_type,
                        .changed = true,
                        .is_fixed = false,
                    };

                    added += 1;
                }
            }
        }
    }

    pub fn randomizeDecorations(self: *TreeState) void {
        var any_changed = false;

        // Randomize only ornaments and lights, not foliage
        for (1..constants.TREE_LINES + 1) |line_num| {
            const width = self.width_by_line[line_num];
            if (width > 2) {
                var prev_was_ornament: bool = false;

                for (1..width - 1) |col| {
                    var cell = &self.cells[line_num][col];

                    // Check both current and next/previous cells to maintain spacing
                    const is_decoration = cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light;

                    if (is_decoration) {
                        const stability: f32 = if (cell.cell_type == constants.CellType.ornament) constants.ORNAMENT_STABILITY else constants.LIGHT_STABILITY;
                        const rand_val = self.rng.random().float(f32);

                        // Apply spacing rules: only change if previous was not an ornament
                        const should_change = rand_val > stability and !prev_was_ornament;

                        // Check next cell if it exists
                        var next_will_be_ornament = false;
                        if (col < width - 2) {
                            const next_cell = &self.cells[line_num][col + 1];
                            next_will_be_ornament = next_cell.cell_type == constants.CellType.ornament or next_cell.cell_type == constants.CellType.light;
                        }

                        if (should_change and !next_will_be_ornament) {
                            // Change this cell
                            const is_light = self.rng.random().float(f32) < 0.4;
                            const new_type = if (is_light) constants.CellType.light else constants.CellType.ornament;

                            // Generate new character - use foliage to separate from previous ornament
                            var new_char: u8 = undefined;
                            if (is_light) {
                                new_char = constants.LIGHT_CHAR;
                            } else {
                                new_char = constants.ORNAMENT_CHARS[self.rng.random().uintLessThan(usize, constants.ORNAMENT_CHARS.len)];
                            }

                            const new_color = colors.getRandomColorForCell(new_type, self.rng.random());

                            cell.* = TreeCell{
                                .char = new_char,
                                .color = new_color,
                                .cell_type = new_type,
                                .changed = true,
                                .is_fixed = false,
                            };

                            any_changed = true;
                            prev_was_ornament = true;
                        } else {
                            // Keep existing cell, use foliage if previous was decoration
                            if (prev_was_ornament and (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light)) {
                                // Force foliage between decorations
                                cell.char = if (self.rng.random().uintLessThan(u8, 2) == 1) constants.FOLIAGE_LEFT else constants.FOLIAGE_RIGHT;
                                cell.cell_type = constants.CellType.foliage;
                                cell.changed = true;
                            }
                            prev_was_ornament = (cell.cell_type == constants.CellType.ornament or cell.cell_type == constants.CellType.light);
                        }
                    } else {
                        // Non-ornament cell
                        prev_was_ornament = false;
                    }
                }
            }
        }

        // If nothing changed, mark one random decoration as changed to prevent animation stalling
        if (!any_changed) {
            self.markOneRandomDecorationChanged();
        }

        // Ensure minimum ornaments per line after randomization
        for (1..constants.TREE_LINES + 1) |line_num| {
            const width = self.width_by_line[line_num];
            if (width > 2) {
                self.ensureMinimumOrnaments(line_num, width);
            }
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

                        // Ensure minimum ornaments per line to prevent sparse lines
                        self.ensureMinimumOrnaments(line_num, width);
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
