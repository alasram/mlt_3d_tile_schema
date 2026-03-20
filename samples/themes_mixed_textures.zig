//! Theme with mixed texture use: default material is untextured, theme alternate is textured.
//!
//! This sample exercises the UV/texture rules:
//!   - UVs are allowed even when the default material has no texture; they are simply unused.
//!   - When a texture is present but the vertex buffer has no UVs, the texture is silently ignored.
//!
//! Producer guidance: if any theme material for a primitive may use textures, include UVs in the
//! vertex buffer even when the default material is untextured. This ensures the textured theme
//! renders correctly when selected by the style sheet. If UVs are absent and a textured theme is
//! selected, the texture is silently ignored and the primitive falls back to unlit geometry.
//!
//! In this sample the default material is a flat color (no texture). The "satellite" theme applies
//! a base_color_texture. UVs are present in the vertex buffer so the textured theme works correctly
//! when selected.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id_default: schema.MaterialId = 1;
const material_id_satellite: schema.MaterialId = 2;

// UVs are included even though the default material has no texture, so that the "satellite"
// theme material (which uses a base_color_texture) renders correctly when selected.
const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    .material_id = material_id_default,
    .theme_material_ids = &[_]schema.MaterialId{material_id_satellite},
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
        // UVs present to support the textured "satellite" theme. Unused by the default material.
        .uvs = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "building",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

// Default material: flat color, no texture. UVs in the vertex buffer are unused.
const material_default = schema.Material{
    .id = material_id_default,
    .name = "default",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.8, .y = 0.75, .z = 0.7, .w = 1.0 },
};

// Satellite theme: building facade from a photo texture. Requires UVs in the vertex buffer.
const material_satellite = schema.Material{
    .id = material_id_satellite,
    .name = "satellite",
    .shading_model = .lambertian,
    .base_color_texture = schema.Texture{
        .kind = .base_color,
        .data = .{ .url = "https://example.com/facade.jpg" },
    },
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{ material_default, material_satellite },
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
