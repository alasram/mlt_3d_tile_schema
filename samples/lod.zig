//! Building variants: a detailed and a simplified building placed as separate instances.
//!
//! Note: zoom-level tiling is the primary LOD mechanism in this format — a higher zoom
//! tile contains more detail. Intra-tile LOD (variant selection within a single tile) is
//! deferred to a future extension. This sample shows two building geometries placed at
//! different positions within the tile, each as a regular ObjectInstance.

const schema = @import("format_3d_schema");

const primitive_id_detailed: schema.PrimitiveId = 1;
const primitive_id_simple: schema.PrimitiveId = 2;
const object_id_detailed: schema.ObjectId = 1;
const object_id_simple: schema.ObjectId = 2;
const material_id: schema.MaterialId = 1;

const primitive_detailed = schema.Primitive3D{
    .id = primitive_id_detailed,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const primitive_simple = schema.Primitive3D{
    .id = primitive_id_simple,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object_detailed = schema.Object3D{
    .id = object_id_detailed,
    .name = "building_detailed",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_detailed},
};

const object_simple = schema.Object3D{
    .id = object_id_simple,
    .name = "building_simple",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_simple},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{ primitive_detailed, primitive_simple },
    .objects = &[_]schema.Object3D{ object_detailed, object_simple },
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        // Detailed building placed at (512, 512, 0).
        .{
            .object_id = object_id_detailed,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 512, 512, 0, 1 },
            },
        },
        // Simple building placed at (2048, 2048, 0).
        .{
            .object_id = object_id_simple,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 2048, 2048, 0, 1 },
            },
        },
    },
};

pub fn main() void {
    _ = tile;
}
