//! Primitive restart for line_strip and triangle_strip.
//!
//! When primitive_restart = true on an IndexBuffer, the sentinel value 0xFFFFFFFF
//! ends the current strip and starts a new one. This allows multiple disconnected
//! road polylines or triangle strips to be batched into a single primitive, avoiding
//! an explosion of small primitives per tile.
//!
//! primitive_restart is only valid for line_strip and triangle_strip topologies.
//! triangle_fan is not part of the schema (not supported in WebGPU).

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

// triangle_strip with restart: multiple strips in one index buffer separated by 0xFFFFFFFF.
const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangle_strip,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            // 0xFFFFFFFF in the index stream ends the current strip and begins a new one.
            .primitive_restart = true,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "strips",
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
