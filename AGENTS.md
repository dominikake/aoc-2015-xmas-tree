# Agent Guidelines for AoC 2015 Christmas Tree

## Build Commands
- `zig build` - Build the project
- `zig run` - Build and run the Christmas tree animation
- No test framework present

## Code Style Guidelines

### Imports
Always import std first, then local modules with @import("filename.zig")
```zig
const std = @import("std");
const local_module = @import("local_module.zig");
```

### Naming Conventions
- Types: PascalCase (TreeCell, AnimationController)
- Functions: camelCase (generateTree, calculateCenterOffset)
- Constants: UPPER_CASE (TREE_HEIGHT, ANIMATION_INTERVAL_NS)
- Variables: snake_case for local variables

### Error Handling
Use `!void` return types for functions that can fail, handle with `try`
```zig
pub fn run(self: *AnimationController) !void {
    try self.terminal_renderer.renderTree(self.tree_state);
}
```

### Zig 0.15.2 Specific
- File.writer() requires buffer parameter: `file.writer(&buffer)`
- Use std.mem.zeroes() for zero-initialization
- DefaultPrng.init() expects u64 seed
- std.time.sleep is unavailable, use std.posix.nanosleep(seconds, nanoseconds)
- Avoid C imports when possible; prefer POSIX APIs or simplified alternatives
- writeAll/writeByte APIs moved to File directly, not Writer
- ComptimeStringMap replaced with switch statements or StaticStringMap

### Module Organization
- Separate concerns: animation, colors, constants, renderer, tree state
- No comments in code (follow existing style)
- Use pub const for public enums and constants
- Keep functions focused and small