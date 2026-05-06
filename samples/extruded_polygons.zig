const schema = @import("format_3d_schema");

/// Native extruded polygon: a building footprint extruded uniformly by `Primitive3D.height`.
///
/// Demonstrates the standalone OSM-buildings case. The producer ships only:
/// - the footprint ring as `vec3i32` positions (z = base elevation, here 0 = ground),
/// - `Primitive3D.ring_offsets` delimiting the exterior ring,
/// - `Primitive3D.height` baked onto the polygon primitive.
///
/// Unlike MVT, no style rule is required to extrude — `height` is a first-class schema
/// field. The renderer triangulates the cap and generates side walls from the footprint.
///
/// Two buildings share one Object3D named "buildings" (the MVT layer label); each carries
/// its own height + feature attribution. Footprint is a 4-vertex rectangle (open ring).
pub fn main() void {
    // Building A footprint: 4 vertices × 12 bytes (vec3i32) = 48 bytes.
    const building_a_positions = [_]u8{0} ** 48;
    // Building B footprint: same shape.
    const building_b_positions = [_]u8{0} ** 48;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .vertex_buffers = &.{
            .{ .id = 0, .vertex_count = 4, .positions = &building_a_positions },
            .{ .id = 1, .vertex_count = 4, .positions = &building_b_positions },
        },
        .primitives = &.{
            // Building A: 18 m high (1800 extent units at z_scale = 0.01).
            .{
                .id = 0,
                .topology = .polygon,
                .vertex_buffer_id = 0,
                .ring_offsets = &.{ 0, 4 },
                .height = 1800,
                .feature_id = 0,
            },
            // Building B: 7 m high.
            .{
                .id = 1,
                .topology = .polygon,
                .vertex_buffer_id = 1,
                .ring_offsets = &.{ 0, 4 },
                .height = 700,
                .feature_id = 1,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{ 0, 1 },
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "commercial" } },
                    .{ .name = "name", .value = .{ .string = "Office Tower" } },
                },
            },
            .{
                .id = 1,
                .properties = &.{
                    .{ .name = "type", .value = .{ .string = "residential" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
        },
    };
    _ = tile;
}
