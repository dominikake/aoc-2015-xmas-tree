const std = @import("std");

pub const CellType = enum {
    star,
    foliage,
    ornament,
    light,
    trunk,
};

// Tree dimensions
pub const TREE_HEIGHT = 28; // Reduced to remove duplicate line
pub const TREE_LINES = 24; // Actual tree lines (not counting star or trunk)
pub const TRUNK_LINES = 3;
pub const TRUNK_WIDTH = 3;

// Character sets
pub const FOLIAGE_LEFT = '>';
pub const FOLIAGE_RIGHT = '<';
pub const TRUNK_CHAR = '|';
pub const STAR_CHAR = '*';

pub const ORNAMENT_CHARS = [_]u8{ 'o', '0', '@' };
pub const LIGHT_CHAR = '*';

// Animation timing
pub const ANIMATION_INTERVAL_NS = 2_500_000_000; // 2.5 seconds in nanoseconds
pub const REFRESH_INTERVAL_MS = 100; // 100ms for 10 FPS (less blinking)

// Randomization stability factors
pub const ORNAMENT_STABILITY = 0.7; // 70% chance to stay the same
pub const LIGHT_STABILITY = 0.3; // 30% chance to stay the same

// Decoration density control
pub const BASE_DECORATION_DENSITY = 0.25; // Base probability for decorations
pub const DENSITY_VARIANCE = 0.15; // Variance in decoration density per line
pub const MAX_CONSECUTIVE_DECORATIONS = 2; // Maximum consecutive decorations
