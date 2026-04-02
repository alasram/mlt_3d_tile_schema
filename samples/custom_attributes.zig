const schema = @import("format_3d_schema");

/// Custom vertex attributes: per-vertex data values (i32 or f32) that the style sheet
/// maps to visual properties. Replaces baked-in per-vertex colors — producers encode
/// the underlying data and let the style sheet decide how to visualize it.
pub fn main() void {
    // 6 vertices (two triangles).
    const positions = [_]u8{0} ** 72; // 6 × 12 bytes
    // Custom attribute data: 6 × 4 bytes each.
    const temperature_data = [_]u8{0} ** 24;
    const elevation_data = [_]u8{0} ** 24;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{
                .id = 0,
                .topology = .triangles,
                .vertex_buffer = .{
                    .vertex_count = 6,
                    .positions = &positions,
                    .custom_attributes = &.{
                        .{
                            .name = "temperature",
                            .attribute_type = .f32,
                            .data = &temperature_data,
                        },
                        .{
                            .name = "elevation",
                            .attribute_type = .i32,
                            .data = &elevation_data,
                        },
                    },
                },
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "terrain",
                .primitive_ids = &.{0},
            },
        },
        .features = &.{},
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
