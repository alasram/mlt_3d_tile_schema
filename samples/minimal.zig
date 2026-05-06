const schema = @import("format_3d_schema");

/// Minimal 3D tile: one triangle primitive, one object, one instance.
/// Demonstrates the bare minimum structure. No features, no custom attributes.
/// The style sheet controls all visual appearance (color, shading, etc.).
pub fn main() void {
    // One triangle: 3 vertices × 12 bytes (vec3i32) = 36 bytes.
    const positions = [_]u8{0} ** 36;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{
                .id = 0,
                .vertex_count = 3,
                .positions = &positions,
            },
        },
        .primitives = &.{
            .{
                .id = 0,
                .topology = .triangles,
                .vertex_buffer_id = 0,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{0},
            },
        },
        .features = &.{},
        .scene = &.{
            .{
                .object_id = 0,
            },
        },
    };
    _ = tile;
}
