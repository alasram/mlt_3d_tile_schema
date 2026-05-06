const schema = @import("format_3d_schema");

/// Polygon with holes: a building footprint with a courtyard.
///
/// Demonstrates `Primitive3D.ring_offsets` with multiple rings:
/// - The first ring (vertices [0..4]) is the exterior building outline.
/// - The second ring (vertices [4..8]) is a courtyard hole.
///
/// `ring_offsets = .{ 0, 4, 8 }` says: ring 0 spans [0, 4), ring 1 spans [4, 8). All
/// rings are stored OPEN (no explicit closing vertex); the renderer closes implicitly.
/// The polygon is extruded uniformly by `Primitive3D.height`.
pub fn main() void {
    // 4 exterior vertices + 4 hole vertices = 8 vertices × 12 bytes = 96 bytes.
    const positions = [_]u8{0} ** 96;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{ .id = 0, .vertex_count = 8, .positions = &positions },
        },
        .primitives = &.{
            .{
                .id = 0,
                .topology = .polygon,
                .vertex_buffer_id = 0,
                // Two rings: exterior [0..4) and hole [4..8).
                .ring_offsets = &.{ 0, 4, 8 },
                // Building is 12 m tall (1200 extent units at z_scale = 0.01).
                .height = 1200,
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
                    .{ .name = "name", .value = .{ .string = "Courtyard House" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
