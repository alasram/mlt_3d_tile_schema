//! LOD (level-of-detail): one LodGroupInstance with two variants.
//!
//! The client picks a variant (e.g. by distance or geometric_error). Rank 0 = most
//! detailed, higher rank = coarser. Optional geometric_error on the tile or variant
//! can drive refinement.

const schema = @import("format_3d_schema");

const primitive_id_detailed: schema.PrimitiveId = 1;
const primitive_id_simple: schema.PrimitiveId = 2;
const object_id_detailed: schema.ObjectId = 1;
const object_id_simple: schema.ObjectId = 2;
const material_id: schema.MaterialId = 1;

const primitive_detailed = schema.Primitive3D{
    .id = primitive_id_detailed,
    .name = "building_detailed",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const primitive_simple = schema.Primitive3D{
    .id = primitive_id_simple,
    .name = "building_simple",
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const object_detailed = schema.Object3D{
    .id = object_id_detailed,
    .name = "building_detailed",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_detailed, .primitive_to_object = null },
    },
};

const object_simple = schema.Object3D{
    .id = object_id_simple,
    .name = "building_simple",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_simple, .primitive_to_object = null },
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
    .geometric_error = .{ .f32 = 2.0 },
    .features = &[_]schema.Feature{},
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{ primitive_detailed, primitive_simple },
    .objects = &[_]schema.Object3D{ object_detailed, object_simple },
    .scene = &[_]schema.SceneItem{
        .{ .lod_group = schema.LodGroupInstance{
            .group_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 512.0, .y = 512.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .variants = &[_]schema.LodVariant{
                .{ .object_id = object_id_detailed, .rank = 0, .geometric_error = .{ .f32 = 0.5 } },
                .{ .object_id = object_id_simple, .rank = 1, .geometric_error = null },
            },
            .default_variant_rank = 0,
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
