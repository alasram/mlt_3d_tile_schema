//! Instancing: one simple shape (a box) placed multiple times with different transforms.
//!
//! The same Object3D is referenced by several ObjectInstances, each with its own
//! object_to_tile transform. This avoids duplicating geometry and is typical for
//! trees, buildings, or street furniture.

const schema = @import("format_3d_schema");

const primitive_id_box: schema.PrimitiveId = 1;
const object_id_box: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_box = schema.Primitive3D{
    .id = primitive_id_box,
    .name = "box",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .index_type = .u16,
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .positions = .{
            .position_type = .{ .shape = .vec3, .scalar = .f32 },
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const object_box = schema.Object3D{
    .id = object_id_box,
    .name = "box",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_box, .primitive_to_object = null },
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
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive_box},
    .objects = &[_]schema.Object3D{object_box},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_box,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 100.0, .y = 200.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = null,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_box,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 500.0, .y = 600.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.5 } },
            } },
            .feature_id = null,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_box,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 1000.0, .y = 100.0, .z = 10.0 },
                .orientation = .{ .quaternion = .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 } },
            } },
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
