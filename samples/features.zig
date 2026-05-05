const schema = @import("format_3d_schema");

/// Feature properties for style-driven filtering, coloring, and labeling.
/// Features mirror the MVT property model: named key-value pairs attached to primitives.
/// The style sheet uses these properties to control appearance — the tile carries no materials.
///
/// Two distinct buildings share one vertex buffer (same shape), each emitted as its own
/// `Primitive3D` with its own `feature_id`. Both primitives sit in a single Object3D named
/// "buildings" (the MVT layer label). A separate vertex buffer + primitive carries the road.
pub fn main() void {
    // Shared building shape: 3 placeholder vertices.
    const building_positions = [_]u8{0} ** 36;
    // Road shape.
    const road_positions = [_]u8{0} ** 36;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{ .id = 0, .vertex_count = 3, .positions = &building_positions },
            .{ .id = 1, .vertex_count = 3, .positions = &road_positions },
        },
        .primitives = &.{
            // Two buildings share the same vertex buffer (same shape) but carry distinct
            // per-primitive feature attribution.
            .{ .id = 0, .topology = .triangles, .vertex_buffer_id = 0, .feature_id = 0 },
            .{ .id = 1, .topology = .triangles, .vertex_buffer_id = 0, .feature_id = 1 },
            // Road primitive.
            .{ .id = 2, .topology = .triangles, .vertex_buffer_id = 1, .feature_id = 2 },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{ 0, 1 },
            },
            .{
                .id = 1,
                .name = "roads",
                .primitive_ids = &.{2},
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
            .{ .object_id = 0 },
            .{ .object_id = 1 },
        },
    };
    _ = tile;
}
