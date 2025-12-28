const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc-2015-xmas-tree",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link against C library for signal handling on Unix systems
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the AoC 2015 Christmas Tree");
    run_step.dependOn(&run_cmd.step);

    // Add test support
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Add individual test modules
    const test_colors = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/colors.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_test_colors = b.addRunArtifact(test_colors);

    const test_colors_step = b.step("test-colors", "Run color tests");
    test_colors_step.dependOn(&run_test_colors.step);
}
