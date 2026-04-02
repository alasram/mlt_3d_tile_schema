const schema = @import("format_3d_schema");

/// Combined scene: roads with banking angles and trees via instancing.
/// Demonstrates multiple object types and features in a single tile.
pub fn main() void {
    // Road: line_strip with 5 vertices.
    const road_positions = [_]u8{0} ** 60; // 5 × 12 bytes
    const road_banking = [_]u8{0} ** 20; // 5 × 4 bytes

    // Tree trunk: 3 vertices.
    const trunk_positions = [_]u8{0} ** 36;
    // Tree canopy: 4 vertices.
    const canopy_positions = [_]u8{0} ** 48;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            // Road polyline with banking angles for ribbon extrusion.
            .{
                .id = 0,
                .topology = .line_strip,
                .vertex_buffer = .{
                    .vertex_count = 5,
                    .positions = &road_positions,
                    .banking_angles = &road_banking,
                },
            },
            // Tree trunk.
            .{
                .id = 1,
                .topology = .triangles,
                .vertex_buffer = .{ .vertex_count = 3, .positions = &trunk_positions },
            },
            // Tree canopy.
            .{
                .id = 2,
                .topology = .triangles,
                .vertex_buffer = .{ .vertex_count = 4, .positions = &canopy_positions },
            },
        },
        .objects = &.{
            .{ .id = 0, .name = "roads", .primitive_ids = &.{0} },
            .{ .id = 1, .name = "trees", .primitive_ids = &.{ 1, 2 } },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "road_class", .value = .{ .string = "primary" } },
                    .{ .name = "lanes", .value = .{ .int = 3 } },
                },
            },
            .{
                .id = 1,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "tree" } },
                    .{ .name = "species", .value = .{ .string = "maple" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0, .feature_id = 0 },
            // Three tree instances at different positions.
            .{
                .object_id = 1,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 100, 50, 0, 1 },
                },
                .feature_id = 1,
            },
            .{
                .object_id = 1,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 400, 50, 0, 1 },
                },
                .feature_id = 1,
            },
            .{
                .object_id = 1,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 700, 50, 0, 1 },
                },
                .feature_id = 1,
            },
        },
    };
    _ = tile;
}
