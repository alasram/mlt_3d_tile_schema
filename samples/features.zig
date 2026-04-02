const schema = @import("format_3d_schema");

/// Feature properties for style-driven filtering, coloring, and labeling.
/// Features mirror the MVT property model: named key-value pairs attached to instances.
/// The style sheet uses these properties to control appearance — the tile carries no materials.
pub fn main() void {
    const positions = [_]u8{0} ** 36;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{ .id = 0, .topology = .triangles, .vertex_buffer = .{ .vertex_count = 3, .positions = &positions } },
            .{ .id = 1, .topology = .triangles, .vertex_buffer = .{ .vertex_count = 3, .positions = &positions } },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{0},
            },
            .{
                .id = 1,
                .name = "roads",
                .primitive_ids = &.{1},
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "commercial" } },
                    .{ .name = "height_m", .value = .{ .float = 45.0 } },
                    .{ .name = "name", .value = .{ .string = "Office Tower" } },
                },
            },
            .{
                .id = 1,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "residential" } },
                    .{ .name = "height_m", .value = .{ .float = 12.5 } },
                },
            },
            .{
                .id = 2,
                .properties = &.{
                    .{ .name = "road_class", .value = .{ .string = "primary" } },
                    .{ .name = "lanes", .value = .{ .int = 4 } },
                },
            },
        },
        .scene = &.{
            // Two building instances with different features
            .{ .object_id = 0, .feature_id = 0 },
            .{ .object_id = 0, .feature_id = 1 },
            // Road instance
            .{ .object_id = 1, .feature_id = 2 },
        },
    };
    _ = tile;
}
