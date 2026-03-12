//! Materials with PBR semantics: texture and material-attribute bindings.
//!
//! TileSemantics assign well-known semantics (base_color, metallic, roughness, etc.)
//! so a renderer can interpret the tile as PBR without project-specific names.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .name = "mesh",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{
            .{ .id = 1, .name = null, .value_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .scale = null, .element_count = 0, .data = &[_]u8{} },
            .{ .id = 2, .name = null, .value_type = .{ .shape = .vec2, .scalar = .f32 }, .encoding = .none, .scale = null, .element_count = 0, .data = &[_]u8{} },
        },
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "mesh",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id, .primitive_to_object = null },
    },
};

const material = schema.Material{
    .id = material_id,
    .name = "pbr",
    .textures = &[_]schema.Texture{
        .{ .id = 1, .path = "file://basecolor.png", .format = .{ .shape = .vec4, .scalar = .u8, .colorspace = .srgb } },
        .{ .id = 2, .path = "file://metallic_roughness.png", .format = .{ .shape = .vec2, .scalar = .u8 } },
    },
    .attributes = &[_]schema.MaterialAttribute{
        .{ .id = 1, .name = "baseColorFactor", .value = .{ .vec4 = .{ .{ .f32 = 1.0 }, .{ .f32 = 1.0 }, .{ .f32 = 1.0 }, .{ .f32 = 1.0 } } } },
        .{ .id = 2, .name = "metallicFactor", .value = .{ .scalar = .{ .f32 = 0.0 } } },
        .{ .id = 3, .name = "roughnessFactor", .value = .{ .scalar = .{ .f32 = 0.5 } } },
    },
};

pub const tile = schema.Tile3D{
    .extents = .{ .x = 4096, .y = 4096, .z = 256 },
    .features = &[_]schema.Feature{},
    .semantics = schema.TileSemantics{
        .texture_semantics = &[_]schema.TextureSemanticBinding{
            .{
                .material_id = material_id,
                .texture_id = 1,
                .r_component_semantic = .base_color_r,
                .g_component_semantic = .base_color_g,
                .b_component_semantic = .base_color_b,
                .a_component_semantic = .base_color_a,
            },
            .{
                .material_id = material_id,
                .texture_id = 2,
                .r_component_semantic = .metallic,
                .g_component_semantic = .roughness,
                .b_component_semantic = null,
                .a_component_semantic = null,
            },
        },
        .material_attribute_semantics = &[_]schema.MaterialAttributeSemanticBinding{
            .{ .material_id = material_id, .attribute_id = 1, .semantic = .base_color_factor },
            .{ .material_id = material_id, .attribute_id = 2, .semantic = .metallic_factor },
            .{ .material_id = material_id, .attribute_id = 3, .semantic = .roughness_factor },
        },
        .vertex_attribute_semantics = &[_]schema.VertexAttributeSemanticBinding{
            .{ .primitive_id = primitive_id, .attribute_id = 1, .semantic = .normal },
            .{ .primitive_id = primitive_id, .attribute_id = 2, .semantic = .texcoord_0 },
        },
    },
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
