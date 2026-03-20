const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const schema_mod = b.addModule("format_3d_schema", .{
        .root_source_file = b.path("format_3d_schema.zig"),
    });

    const sample_names = &[_][]const u8{
        "minimal",
        "roads_tangent",
        "instancing",
        "features",
        "scene_roads_trees",
        "materials_pbr",
        "bounding_volumes",
        "points",
        "encoding",
        "primitive_restart",
        "validate_tile",
        "themes",
        "themes_mixed_textures",
        "object_primitive_transforms",
    };

    for (sample_names) |name| {
        const sample_mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("samples/{s}.zig", .{name})),
            .target = target,
            .optimize = optimize,
        });
        sample_mod.addImport("format_3d_schema", schema_mod);

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = sample_mod,
        });
        b.installArtifact(exe);
    }
}
