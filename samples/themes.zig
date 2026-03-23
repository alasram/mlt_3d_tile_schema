//! Themes: day/night material switching via per-primitive theme_material_ids.
//!
//! Each Primitive3D declares a default material_id and an optional list of
//! theme_material_ids. The default material is applied when no style sheet override
//! is active. A style sheet selects an alternate material by picking any ID from
//! theme_material_ids (e.g. choosing a "night" appearance by selecting material_id_night).
//! This allows scene-wide appearance switching without duplicating geometry.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id_day: schema.MaterialId = 1;
const material_id_night: schema.MaterialId = 2;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    // Default material: day appearance.
    .material_id = material_id_day,
    // Alternate material available for style sheet selection (e.g. night theme).
    .theme_material_ids = &[_]schema.MaterialId{material_id_night},
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "building",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

// Day material: bright facade.
const material_day = schema.Material{
    .id = material_id_day,
    .name = "day",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.9, .y = 0.85, .z = 0.75, .w = 1.0 },
};

// Night material: dark facade with slight emissive for lit windows.
const material_night = schema.Material{
    .id = material_id_night,
    .name = "night",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.1, .y = 0.1, .z = 0.15, .w = 1.0 },
    .emissive_factor = .{ .x = 0.05, .y = 0.05, .z = 0.1 },
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{ material_day, material_night },
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
