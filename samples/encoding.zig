//! Fixed vertex types and z_scale: vec3i32 positions, vec3f32 normals, vec2u16 UVs.
//!
//! Positions are always vec3i32 (3 × i32, 12 bytes per vertex) stored as-is.
//! z_scale on the tile converts integer Z values to meters:
//!   height_in_meters = z_value * z_scale
//! This allows building heights and terrain to be expressed in real-world units
//! without changing the integer position representation.
//!
//! Normals are vec3f32 (3 × f32, 12 bytes per vertex), not necessarily unit length.
//! UVs are vec2u16 (2 × u16, 4 bytes per vertex); 0 → 0.0, 65535 → 1.0.
//! Colors are vec4u8 (4 × u8, 4 bytes per vertex); divided by 255 in shading.
//!
//! All buffers are stored as-is. No delta encoding. Binary compression (e.g. zstd)
//! is applied by the MLT encoding layer.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

// Building mesh: positions (vec3i32), normals (vec3f32), UVs (vec2u16).
// z_scale = 0.001 on the tile means Z=1000 → 1.0 meter (millimeter units).
const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        // vec3i32: 3 × i32, 12 bytes per vertex. Stored as-is (no delta encoding).
        .positions = &[_]u8{},
        // vec2u16: 2 × u16, 4 bytes per vertex. 0 → 0.0, 65535 → 1.0.
        // Present because the material has a base_color_texture; without UVs the texture is ignored.
        .uvs = &[_]u8{},
        // vec3f32: 3 × f32, 12 bytes per vertex. Client normalizes before use.
        .normals = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "building",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
    .base_color_texture = schema.Texture{
        .kind = .base_color,
        .data = .{ .url = "file://facade.png" },
    },
};

pub const tile = schema.Tile3D{
    .extent = 4096,
    // z_scale: 1 extent unit = 0.001 meters (millimeter precision for Z).
    // A building vertex at Z=15000 is 15.0 meters tall.
    .z_scale = 0.001,
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
