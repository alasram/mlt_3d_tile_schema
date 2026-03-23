//! Minimal tile: one primitive, one object, one instance.
//! No features, no material textures. Demonstrates the bare structure of the schema.

const schema = @import("format_3d_schema");

const primitive_id_cube: schema.PrimitiveId = 1;
const object_id_cube: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_cube = schema.Primitive3D{
    .id = primitive_id_cube,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .element_count = 0,
            .data = &[_]u8{},
        },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object_cube = schema.Object3D{
    .id = object_id_cube,
    .name = "cube",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_cube},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_cube},
    .objects = &[_]schema.Object3D{object_cube},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        .{ .object_id = object_id_cube },
    },
};

pub fn main() void {
    _ = tile;
}
