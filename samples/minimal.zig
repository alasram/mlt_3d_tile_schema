//! Minimal tile: one primitive, one object, one instance.
//! No semantics, no features. Demonstrates the bare structure of the schema.

const schema = @import("format_3d_schema");

const primitive_id_cube: schema.PrimitiveId = 1;
const object_id_cube: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_cube = schema.Primitive3D{
    .id = primitive_id_cube,
    .name = "cube",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .index_type = .u16,
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .positions = .{
            .position_type = .{ .shape = .vec3, .scalar = .f32 },
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const object_cube = schema.Object3D{
    .id = object_id_cube,
    .name = "cube",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_cube, .primitive_to_object = null },
    },
};

const material = schema.Material{
    .id = material_id,
    .name = "default",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{},
};

pub const tile = schema.Tile3D{
    .extents = .{ .x = 4096, .y = 4096, .z = 256 },
    .features = &[_]schema.Feature{},
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_cube},
    .objects = &[_]schema.Object3D{object_cube},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_cube,
            .object_to_tile = null,
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
