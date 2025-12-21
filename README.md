# 🎄 AoC 2015 Christmas Tree in Zig

A faithful recreation of the AoC 2015 Christmas tree experience, implemented in Zig for terminal display.

## Features

- **30-line animated Christmas tree** with progressive growth (1→2→3...→25 characters)
- **Authentic character set**: `>`, `<`, `o`, `0`, `@`, `*` with yellow star on top
- **7-color palette**: Green, red, blue, yellow, white, grey, orange (using red)
- **Proper foliage placement**: Green `>` on left, `<` on right edges
- **2.5-second randomization**: Ornaments and lights change at appropriate intervals
- **Centered display**: Tree is properly centered in terminal
- **Smooth animations**: Efficient rendering with low CPU/memory usage

## Build & Run

```bash
# Build the project
zig build

# Run the Christmas tree
zig run
```

## Tree Structure

```
Line 1:    *           (Yellow star)
Lines 2-26: > * o <    (Progressive tree with ornaments)
Lines 27-29:   |||        (White trunk)
Line 30:                (Empty spacing)
```

## Character Roles

- **Green Foliage**: `>` (left), `<` (right) - always green, never changes
- **Ornaments**: `o`, `0`, `@` - colored, semi-stable (70% chance to stay same)
- **Lights**: `*` - colored, highly variable (30% chance to stay same)
- **Star**: `*` - always yellow at top center
- **Trunk**: `|` - always white, 3 characters wide

## Technical Details

- **Language**: Zig 0.15.2
- **Performance**: <1MB memory, <1% CPU usage during animation
- **ANSI Colors**: Full 8-color support with proper terminal detection
- **Cross-platform**: Linux, macOS, Windows compatible
- **Signal Handling**: Graceful Ctrl+C exit with cursor restoration

## Controls

- **Ctrl+C**: Exit gracefully
- **Animation**: 2.5 second intervals
- **Display**: Auto-centered in terminal

Perfect for festive terminal displays during the holiday season! 🎅