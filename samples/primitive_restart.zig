const schema = @import("format_3d_schema");

/// Triangle strip with primitive restart: multiple disconnected strips packed into one
/// index buffer using the 0xFFFFFFFF sentinel value to separate them.
pub fn main() void {
    // 8 vertices × 12 bytes = 96 bytes.
    const positions = [_]u8{0} ** 96;
    // 9 indices (two strips: [0,1,2,3] + restart + [4,5,6,7]) × 4 bytes = 36 bytes.
    const indices = [_]u8{0} ** 36;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{
                .id = 0,
                .topology = .triangle_strip,
                .vertex_buffer = .{
                    .indices = .{
                        .primitive_restart = true,
                        .element_count = 9,
                        .data = &indices,
                    },
                    .vertex_count = 8,
                    .positions = &positions,
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
