//! PBR material: base color texture, ORM texture, normal map, and scalar factors.
//!
//! The Material struct has fixed named texture slots (base_color_texture, orm_texture,
//! normal_map_texture, emissive_texture) and fixed scalar factors following glTF 2.0
//! PBR metallic-roughness. No generic attribute lists or semantic bindings needed.
//! UV coordinates must be present in the vertex buffer when textures are used.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

// Primitive with UVs and normals: required alongside textures and normal map.
const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
        // UVs required because the material has textures.
        .uvs = &[_]u8{},
        // Normals required for the normal map to be meaningful.
        .normals = &[_]u8{},
        // Tangents required for tangent-space normal mapping.
        .tangents = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "mesh",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .pbr,

    // Base color: RGBA8 sRGB texture + tint factor.
    .base_color_texture = schema.Texture{
        .kind = .base_color,
        .data = .{ .url = "file://basecolor.png" },
    },
    .base_color_factor = .{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 },

    // ORM: R = Occlusion, G = Roughness, B = Metallic (glTF 2.0 packing).
    .orm_texture = schema.Texture{
        .kind = .orm,
        .data = .{ .url = "file://orm.png" },
    },
    .metallic_factor = 0.0,
    .roughness_factor = 0.5,

    // Tangent-space normal map.
    .normal_map_texture = schema.Texture{
        .kind = .normal_map,
        .data = .{ .url = "file://normal.png" },
    },
};

pub const tile = schema.Tile3D{
    .extent = 4096,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive},
    .objects = &[_]schema.Object3D{object},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        .{ .object_id = object_id },
    },
};

pub fn main() void {
    _ = tile;
}
