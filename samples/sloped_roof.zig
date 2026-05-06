const schema = @import("format_3d_schema");

/// Sloped roof: per-vertex `top_z` replaces uniform `Primitive3D.height`.
///
/// Same 4-vertex rectangular footprint as `extruded_polygons.zig`, but each footprint
/// vertex carries its own absolute roof elevation in `VertexBuffer.top_z`. Two corners
/// reach 20 m, the other two reach 8 m → a pitched roof.
///
/// Validation: when a vertex buffer carries `top_z`, every consuming polygon primitive
/// MUST have `height = null`. The per-vertex roof Z is the source of truth and is
/// mutually exclusive with the uniform primitive-level height (no two ways to express
/// the same value).
pub fn main() void {
    // Footprint: 4 vertices × 12 bytes (vec3i32, z = 0 = ground) = 48 bytes.
    const positions = [_]u8{0} ** 48;
    // Per-vertex roof elevations: 4 × 4 bytes (i32, absolute, in extent units).
    // At z_scale = 0.01, values are 2000 / 800 / 800 / 2000 → 20 m / 8 m / 8 m / 20 m.
    const top_z = [_]u8{
        0xD0, 0x07, 0x00, 0x00, // 2000
        0x20, 0x03, 0x00, 0x00, // 800
        0x20, 0x03, 0x00, 0x00, // 800
        0xD0, 0x07, 0x00, 0x00, // 2000
    };

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{
                .id = 0,
                .vertex_count = 4,
                .positions = &positions,
                .top_z = &top_z,
            },
        },
        .primitives = &.{
            .{
                .id = 0,
                .topology = .polygon,
                .vertex_buffer_id = 0,
                .ring_offsets = &.{ 0, 4 },
                // height MUST be null when the referenced vertex buffer carries top_z.
                .height = null,
                .feature_id = 0,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{0},
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "residential" } },
                    .{ .name = "roof_shape", .value = .{ .string = "gabled" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
