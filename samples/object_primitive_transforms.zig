//! Multi-primitive object: a tree composed of trunk and canopy primitives.
//!
//! An Object3D directly holds a list of primitive IDs; there is no per-primitive
//! transform. Each primitive can reference a different material from the global pool.
//! The object is placed into tile space via a single object_to_tile matrix on the
//! ObjectInstance. Multiple instances share the same geometry at different positions.

const schema = @import("format_3d_schema");

const primitive_id_trunk: schema.PrimitiveId = 1;
const primitive_id_canopy: schema.PrimitiveId = 2;
const object_id_tree: schema.ObjectId = 1;
const material_id_trunk: schema.MaterialId = 1;
const material_id_canopy: schema.MaterialId = 2;

const primitive_trunk = schema.Primitive3D{
    .id = primitive_id_trunk,
    .topology = .triangles,
    .material_id = material_id_trunk,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const primitive_canopy = schema.Primitive3D{
    .id = primitive_id_canopy,
    .topology = .triangles,
    .material_id = material_id_canopy,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

// Tree: trunk and canopy share the same object. Their relative positioning is
// baked into the vertex data in object-local space.
const object_tree = schema.Object3D{
    .id = object_id_tree,
    .name = "tree",
    .primitive_ids = &[_]schema.PrimitiveId{ primitive_id_trunk, primitive_id_canopy },
};

const material_trunk = schema.Material{
    .id = material_id_trunk,
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.4, .y = 0.25, .z = 0.1, .w = 1.0 },
};

const material_canopy = schema.Material{
    .id = material_id_canopy,
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.1, .y = 0.5, .z = 0.1, .w = 1.0 },
};

pub const tile = schema.Tile3D{
    .extent = 4096,
    .materials = &[_]schema.Material{ material_trunk, material_canopy },
    .primitives = &[_]schema.Primitive3D{ primitive_trunk, primitive_canopy },
    .objects = &[_]schema.Object3D{object_tree},
    .features = &[_]schema.Feature{},
    // Same object placed at three positions via separate ObjectInstances.
    .scene = &[_]schema.ObjectInstance{
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 512, 512, 0, 1 },
            },
        },
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 1024, 768, 0, 1 },
            },
        },
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 2048, 1500, 0, 1 },
            },
        },
    },
};

pub fn main() void {
    _ = tile;
}
