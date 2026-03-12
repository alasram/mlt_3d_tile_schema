//! Object with multiple primitives and non-identity primitive_to_object transforms.
//!
//! Each PrimitiveInstance can have a transform from primitive space to object space
//! (matrix or pose). Example: a "tree" object = trunk (scaled/translated) + canopy (posed on top).

const schema = @import("format_3d_schema");

const primitive_id_trunk: schema.PrimitiveId = 1;
const primitive_id_canopy: schema.PrimitiveId = 2;
const object_id_tree: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive_trunk = schema.Primitive3D{
    .id = primitive_id_trunk,
    .name = "trunk",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const primitive_canopy = schema.Primitive3D{
    .id = primitive_id_canopy,
    .name = "canopy",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

// Trunk: scale 0.15 in x/y, 1.0 in z; translate z by 0.5. Canopy: at (0, 0, 1.25) in object space.
pub const object_tree = schema.Object3D{
    .id = object_id_tree,
    .name = "tree",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{
            .primitive_id = primitive_id_trunk,
            .primitive_to_object = schema.Transform{
                .matrix_f64 = .{
                    .{ 0.15, 0.00, 0.00, 0.00 },
                    .{ 0.00, 0.15, 0.00, 0.00 },
                    .{ 0.00, 0.00, 1.00, 0.50 },
                    .{ 0.00, 0.00, 0.00, 1.00 },
                },
            },
        },
        .{
            .primitive_id = primitive_id_canopy,
            .primitive_to_object = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 0.0, .y = 0.0, .z = 1.25 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
        },
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
    .primitives = &[_]schema.Primitive3D{ primitive_trunk, primitive_canopy },
    .objects = &[_]schema.Object3D{object_tree},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_tree,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 512.0, .y = 512.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
