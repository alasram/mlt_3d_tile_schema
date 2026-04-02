const schema = @import("format_3d_schema");

/// Object instancing: the same object placed at multiple positions via transforms.
/// Avoids duplicating geometry — one tree object instanced three times.
pub fn main() void {
    // Trunk: 3 vertices
    const trunk_positions = [_]u8{0} ** 36;
    // Canopy: 4 vertices
    const canopy_positions = [_]u8{0} ** 48;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{ .id = 0, .topology = .triangles, .vertex_buffer = .{ .vertex_count = 3, .positions = &trunk_positions } },
            .{ .id = 1, .topology = .triangles, .vertex_buffer = .{ .vertex_count = 4, .positions = &canopy_positions } },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "trees",
                .primitive_ids = &.{ 0, 1 },
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "species", .value = .{ .string = "oak" } },
                },
            },
        },
        .scene = &.{
            // Three instances of the same tree at different positions.
            // Each shares the same feature_id so the style sheet can style them uniformly.
            .{
                .object_id = 0,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 100, 200, 0, 1 },
                },
                .feature_id = 0,
            },
            .{
                .object_id = 0,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 500, 300, 0, 1 },
                },
                .feature_id = 0,
            },
            .{
                .object_id = 0,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 900, 100, 0, 1 },
                },
                .feature_id = 0,
            },
        },
    };
    _ = tile;
}
