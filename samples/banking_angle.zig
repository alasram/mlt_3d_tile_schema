const schema = @import("format_3d_schema");

/// Banking angle on road polylines: per-vertex i32 in tenths of a degree.
/// Banking angles enable tilted road ribbon creation (e.g. banked highway curves).
/// Without banking angles, only a stroke can be drawn.
pub fn main() void {
    // 4 vertices on a curved road segment.
    const positions = [_]u8{0} ** 48; // 4 × 12 bytes
    const banking = [_]u8{0} ** 16; // 4 × 4 bytes (i32 tenths of degree)

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{
                .id = 0,
                .topology = .line_strip,
                .vertex_buffer = .{
                    .vertex_count = 4,
                    .positions = &positions,
                    .banking_angles = &banking,
                },
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "roads",
                .primitive_ids = &.{0},
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "road_class", .value = .{ .string = "highway" } },
                    .{ .name = "banked", .value = .{ .bool = true } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0, .feature_id = 0 },
        },
    };
    _ = tile;
}
