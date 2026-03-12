//! Strided positions: positions buffer with element_stride.
//!
//! When positions are not tightly packed, element_stride gives the byte distance
//! from one element to the next. Useful for interleaved or padded layouts.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .name = "positions_strided",
    .topology = .points,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = null,
        .positions = .{
            .position_type = .{ .shape = .vec2, .scalar = .i16 },
            .encoding = .none,
            .scale = schema.Scale{ .factor = .{ .f64 = 0.001 }, .order = .scale_before_normalization },
            .element_stride = 8,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "points",
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
