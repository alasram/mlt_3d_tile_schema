const schema = @import("format_3d_schema");

/// Asset Library: shared assets (trees, poles, etc.) stored in a separate MLT file and
/// referenced via the import table. Each import maps an external primitive to a local
/// PrimitiveId. Object3D.primitive_ids references these local IDs like any local primitive.
pub fn main() void {
    // One local primitive (a building).
    const building_positions = [_]u8{0} ** 36;

    const tile = schema.MLT3DScene{
        .extent = 4096,
        .z_scale = 0.01,
        .primitives = &.{
            .{
                .id = 0,
                .topology = .triangles,
                .vertex_buffer = .{
                    .vertex_count = 3,
                    .positions = &building_positions,
                },
            },
        },
        // Import two primitives from external Asset Libraries.
        // Local IDs 100 and 101 are chosen to avoid collision with local primitive ID 0.
        .imports = &.{
            .{
                .library_name = "maplibre_trees",
                .library_primitive_id = 0, // oak tree trunk in the library
                .local_id = 100,
            },
            .{
                .library_name = "maplibre_trees",
                .library_primitive_id = 1, // oak tree canopy in the library
                .local_id = 101,
            },
        },
        .objects = &.{
            .{
                .id = 0,
                .name = "buildings",
                .primitive_ids = &.{0},
            },
            .{
                .id = 1,
                .name = "trees",
                // References imported primitives by their local IDs.
                .primitive_ids = &.{ 100, 101 },
            },
        },
        .features = &.{
            .{
                .id = 0,
                .properties = &.{
                    .{ .name = "species", .value = .{ .string = "oak" } },
                },
            },
        },
        .scene = &.{
            .{ .object_id = 0 },
            // Three tree instances at different positions, all sharing the same feature.
            .{
                .object_id = 1,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 200, 300, 0, 1 },
                },
                .feature_id = 0,
            },
            .{
                .object_id = 1,
                .object_to_tile = .{
                    .{ 1, 0, 0, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 800, 600, 0, 1 },
                },
                .feature_id = 0,
            },
        },
    };
    _ = tile;
}
