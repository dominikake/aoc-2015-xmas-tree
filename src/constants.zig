const std = @import("std");

pub const CellType = enum {
    star,
    foliage,
    ornament,
    light,
    trunk,
};

// Tree dimensions
pub const TREE_HEIGHT = 30;
pub const TREE_LINES = 25; // Actual tree lines (not counting trunk)
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
pub const REFRESH_INTERVAL_MS = 50; // 50ms for 20 FPS

// Randomization stability factors
pub const ORNAMENT_STABILITY = 0.7; // 70% chance to stay the same
pub const LIGHT_STABILITY = 0.3; // 30% chance to stay the same
