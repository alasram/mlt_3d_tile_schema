//! Instancing: one simple shape (a box) placed multiple times with different transforms.
//!
//! The same Object3D is referenced by several ObjectInstances, each with its own
//! object_to_tile matrix. This avoids duplicating geometry and is typical for
//! trees, buildings, or street furniture. Transforms are 4x4 f32 matrices;
//! null means identity.

const schema = @import("format_3d_schema");

const primitive_id_box: schema.PrimitiveId = 1;
const object_id_box: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_box = schema.Primitive3D{
    .id = primitive_id_box,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const object_box = schema.Object3D{
    .id = object_id_box,
    .name = "box",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_box},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
};

pub const tile = schema.Tile3D{
    .extent = 4096,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_box},
    .objects = &[_]schema.Object3D{object_box},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        // Instance 1: translate to (100, 200, 0).
        .{
            .object_id = object_id_box,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 100, 200, 0, 1 },
            },
        },
        // Instance 2: translate to (500, 600, 0) with yaw rotation of 0.5 rad around Z.
        // Column-major: col0=(cos,sin,0,0), col1=(-sin,cos,0,0), col2=(0,0,1,0), col3=(tx,ty,tz,1).
        // cos(0.5) ≈ 0.87758, sin(0.5) ≈ 0.47943
        .{
            .object_id = object_id_box,
            .object_to_tile = schema.Mat4x4f32{
                .{ 0.87758, 0.47943, 0, 0 },
                .{ -0.47943, 0.87758, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 500, 600, 0, 1 },
            },
        },
        // Instance 3: translate to (1000, 100, 10) — elevated placement.
        .{
            .object_id = object_id_box,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 1000, 100, 10, 1 },
            },
        },
    },
};

pub fn main() void {
    _ = tile;
}
