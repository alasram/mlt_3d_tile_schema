//! Triangle strip with primitive restart: IndexBuffer.primitive_restart = true.
//!
//! For line_strip or triangle_strip, the restart index (max value for the index type)
//! starts a new strip. Allows multiple strips in one index buffer.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .name = "strip_with_restart",
    .topology = .triangle_strip,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .index_type = .u16,
            .encoding = .none,
            .primitive_restart = true,
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

const object = schema.Object3D{
    .id = object_id,
    .name = "strips",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id, .primitive_to_object = null },
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
    .primitives = &[_]schema.Primitive3D{primitive},
    .objects = &[_]schema.Object3D{object},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{ .object_id = object_id, .object_to_tile = null, .feature_id = null } },
    },
};

pub fn main() void {
    _ = tile;
}
