//! Point primitives: topology = points.
//! Useful for point clouds, markers, or vegetation points when not using full mesh LOD.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_points = schema.Primitive3D{
    .id = primitive_id,
    .name = "points",
    .topology = .points,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = null,
        .positions = .{
            .position_type = .{ .shape = .vec3, .scalar = .f32 },
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{
            .{ .id = 1, .name = null, .value_type = .{ .shape = .vec4, .scalar = .u8, .normalization = .normalized_unsigned }, .encoding = .none, .scale = null, .element_count = 0, .data = &[_]u8{} },
        },
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "point_cloud",
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
    .semantics = schema.TileSemantics{
        .vertex_attribute_semantics = &[_]schema.VertexAttributeSemanticBinding{
            .{ .primitive_id = primitive_id, .attribute_id = 1, .semantic = .color_0 },
        },
        .texture_semantics = &[_]schema.TextureSemanticBinding{},
        .material_attribute_semantics = &[_]schema.MaterialAttributeSemanticBinding{},
    },
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_points},
    .objects = &[_]schema.Object3D{object},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{ .object_id = object_id, .object_to_tile = null, .feature_id = null } },
    },
};

pub fn main() void {
    _ = tile;
}
