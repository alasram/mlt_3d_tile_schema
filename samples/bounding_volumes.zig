//! Bounding volumes and geometric error: culling and LOD.
//!
//! Primitives and objects can have an optional bounding_volume (box or sphere).
//! Tile and LOD variants can have geometric_error for refinement decisions.

const schema = @import("format_3d_schema");

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .name = "building",
    .topology = .triangles,
    .material_id = material_id,
    .bounding_volume = .{ .box = .{
        .min = .{ .x = -10.0, .y = -10.0, .z = 0.0 },
        .max = .{ .x = 10.0, .y = 10.0, .z = 20.0 },
    } },
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "building",
    .bounding_volume = .{ .sphere = .{
        .center = .{ .x = 0.0, .y = 0.0, .z = 10.0 },
        .radius = 25.0,
    } },
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id, .primitive_to_object = null },
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
    .geometric_error = .{ .f32 = 1.0 },
    .features = &[_]schema.Feature{},
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive},
    .objects = &[_]schema.Object3D{object},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 256.0, .y = 256.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
