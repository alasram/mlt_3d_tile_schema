const schema = @import("format_3d_schema");

/// Points topology: used for labels, icons, and markers.
/// The style sheet controls icon, text, size, and color by matching on feature properties.
/// Points without feature properties render only if a style rule targets them by object name.
pub fn main() void {
    // 4 point positions × 12 bytes = 48 bytes.
    const positions = [_]u8{0} ** 48;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{
                .id = 0,
                .vertex_count = 4,
                .positions = &positions,
            },
        },
        .primitives = &.{
            .{
                .id = 0,
                .topology = .points,
                .vertex_buffer_id = 0,
                .feature_id = 0,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "poi",
                .primitive_ids = &.{0},
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "name", .value = .{ .string = "Gas Station" } },
                    .{ .name = "category", .value = .{ .string = "fuel" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
