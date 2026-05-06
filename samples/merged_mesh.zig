const schema = @import("format_3d_schema");

/// Merged mesh: one shared `VertexBuffer` carrying vertices for many features, with one
/// `Primitive3D` per feature slicing it via its own `IndexBuffer`.
///
/// Producers commonly merge meshes across semantic boundaries for rendering performance
/// (e.g. all asphalt within a tile as a single vertex buffer, regardless of which road
/// each piece belongs to). Decoupling vertex buffers from primitives lets the producer
/// emit one merged vertex buffer plus N primitives — each pointing at the same vertex
/// buffer, each with its own indices and `feature_id` — preserving per-feature attribution
/// (road class, name, lanes, etc.) without splitting the underlying geometry.
///
/// Here 8 shared vertices form two adjacent road quads. Primitive 0 indexes the first 6
/// indices (feature 0, "Main St"); primitive 1 indexes the next 6 (feature 1, "Broadway").
/// Both primitives sit in a single Object3D named "roads" placed once.
pub fn main() void {
    // 8 shared vertices for two adjacent road quads (placeholder bytes).
    const positions = [_]u8{0} ** (8 * 12);
    // 6 indices per road × 4 bytes = 24 bytes each (placeholder).
    const main_st_indices = [_]u8{0} ** (6 * 4);
    const broadway_indices = [_]u8{0} ** (6 * 4);

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            // Single merged vertex buffer holding both roads' vertices.
            .{ .id = 0, .vertex_count = 8, .positions = &positions },
        },
        .primitives = &.{
            // One primitive per road, both indexing into the shared vertex buffer.
            .{
                .id = 0,
                .topology = .triangles,
                .vertex_buffer_id = 0,
                .indices = .{ .element_count = 6, .data = &main_st_indices },
                .feature_id = 0,
            },
            .{
                .id = 1,
                .topology = .triangles,
                .vertex_buffer_id = 0,
                .indices = .{ .element_count = 6, .data = &broadway_indices },
                .feature_id = 1,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "roads",
                .primitive_ids = &.{ 0, 1 },
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "name", .value = .{ .string = "Main St" } },
                    .{ .name = "road_class", .value = .{ .string = "primary" } },
                    .{ .name = "lanes", .value = .{ .int = 4 } },
                },
            },
            .{
                .id = 1,
                .properties = &.{
                    .{ .name = "name", .value = .{ .string = "Broadway" } },
                    .{ .name = "road_class", .value = .{ .string = "secondary" } },
                    .{ .name = "lanes", .value = .{ .int = 2 } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
