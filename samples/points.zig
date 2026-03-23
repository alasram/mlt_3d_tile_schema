//! Point primitives: topology = points with per-vertex colors.
//!
//! Useful for point clouds, markers, or vegetation points.
//! Colors are vec4u8 (RGBA); values in [0, 255] are divided by 255 in shading formulas.
//! UV is valid for point topology (e.g. for sprite atlas coordinates).

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_points = schema.Primitive3D{
    .id = primitive_id,
    .topology = .points,
    .material_id = material_id,
    .vertex_buffer = .{
        .vertex_count = 0,
        .positions = &[_]u8{},
        // Per-vertex RGBA colors. Values divided by 255 in shading.
        .colors = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "point_cloud",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_points},
    .objects = &[_]schema.Object3D{object},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        .{ .object_id = object_id },
    },
};

pub fn main() void {
    _ = tile;
}
