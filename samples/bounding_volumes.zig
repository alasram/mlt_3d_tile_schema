//! Bounding volumes: box on a primitive, sphere on an object, box on an instance.
//!
//! Primitives, objects, and instances can each carry an optional bounding_volume
//! (box or sphere) for view-frustum culling. When absent, consumers may compute
//! bounds from geometry. Instance-level bounding volumes are pre-transformed into
//! tile space, enabling efficient culling without applying the instance matrix.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    .material_id = material_id,
    // Bounding box in primitive-local space.
    .bounding_volume = .{ .box = .{
        .min = .{ .x = -10.0, .y = -10.0, .z = 0.0 },
        .max = .{ .x = 10.0, .y = 10.0, .z = 20.0 },
    } },
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "building",
    // Bounding sphere in object-local space.
    .bounding_volume = .{ .sphere = .{
        .center = .{ .x = 0.0, .y = 0.0, .z = 10.0 },
        .radius = 25.0,
    } },
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
        .{
            .object_id = object_id,
            // Translate to (256, 256, 0).
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 256 },
                .{ 0, 1, 0, 256 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
            // Pre-transformed bounding box in tile space for efficient culling.
            .bounding_volume = .{ .box = .{
                .min = .{ .x = 246.0, .y = 246.0, .z = 0.0 },
                .max = .{ .x = 266.0, .y = 266.0, .z = 20.0 },
            } },
        },
    },
};

pub fn main() void {
    _ = tile;
}
