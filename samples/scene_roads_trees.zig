//! Complex scene: roads and trees in one tile.
//!
//! Roads: line-strip with tangent semantic (style can add width/thickness).
//! Trees: one object (trunk + canopy) instanced at three positions; one instance
//! uses an LOD group. Features attach properties for styling.

const schema = @import("format_3d_schema");

const primitive_id_trunk: schema.PrimitiveId = 1;
const primitive_id_canopy: schema.PrimitiveId = 2;
const primitive_id_road: schema.PrimitiveId = 3;
const object_id_tree: schema.ObjectId = 1;
const object_id_tree_lod1: schema.ObjectId = 2;
const object_id_roads: schema.ObjectId = 3;
const material_id_trunk: schema.MaterialId = 1;
const material_id_canopy: schema.MaterialId = 2;
const material_id_road: schema.MaterialId = 3;

const primitive_trunk = schema.Primitive3D{
    .id = primitive_id_trunk,
    .name = "trunk",
    .topology = .triangles,
    .material_id = material_id_trunk,
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
    .material_id = material_id_canopy,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .index_type = .u16, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{},
    },
};

const primitive_road = schema.Primitive3D{
    .id = primitive_id_road,
    .name = "road",
    .topology = .line_strip,
    .material_id = material_id_road,
    .vertex_buffer = .{
        .indices = null,
        .positions = .{ .position_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .element_count = 0, .data = &[_]u8{} },
        .attributes = &[_]schema.VertexAttribute{
            .{ .id = 1, .name = null, .value_type = .{ .shape = .vec3, .scalar = .f32 }, .encoding = .none, .scale = null, .element_count = 0, .data = &[_]u8{} },
        },
    },
};

const object_tree = schema.Object3D{
    .id = object_id_tree,
    .name = "tree",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_trunk, .primitive_to_object = null },
        .{ .primitive_id = primitive_id_canopy, .primitive_to_object = null },
    },
};

const object_tree_lod1 = schema.Object3D{
    .id = object_id_tree_lod1,
    .name = "tree_lod1",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_canopy, .primitive_to_object = null },
    },
};

const object_roads = schema.Object3D{
    .id = object_id_roads,
    .name = "roads",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_road, .primitive_to_object = null },
    },
};

const material_trunk = schema.Material{
    .id = material_id_trunk,
    .name = "trunk",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{},
};

const material_canopy = schema.Material{
    .id = material_id_canopy,
    .name = "canopy",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{},
};

const material_road = schema.Material{
    .id = material_id_road,
    .name = "road",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{
        .{ .id = 1, .name = "width", .value = .{ .scalar = .{ .f32 = 6.0 } } },
    },
};

pub const features_list = &[_]schema.Feature{
    .{ .feature_id = 1, .name = "type", .value = .{ .string = "tree" } },
    .{ .feature_id = 2, .name = "type", .value = .{ .string = "road" } },
};

pub const tile = schema.Tile3D{
    .extents = .{ .x = 4096, .y = 4096, .z = 256 },
    .features = features_list,
    .semantics = schema.TileSemantics{
        .vertex_attribute_semantics = &[_]schema.VertexAttributeSemanticBinding{
            .{ .primitive_id = primitive_id_road, .attribute_id = 1, .semantic = .tangent },
        },
        .texture_semantics = &[_]schema.TextureSemanticBinding{},
        .material_attribute_semantics = &[_]schema.MaterialAttributeSemanticBinding{},
    },
    .materials = &[_]schema.Material{ material_trunk, material_canopy, material_road },
    .primitives = &[_]schema.Primitive3D{ primitive_trunk, primitive_canopy, primitive_road },
    .objects = &[_]schema.Object3D{ object_tree, object_tree_lod1, object_roads },
    .scene = &[_]schema.SceneItem{
        .{ .lod_group = schema.LodGroupInstance{
            .group_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 512.0, .y = 768.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .variants = &[_]schema.LodVariant{
                .{ .object_id = object_id_tree, .rank = 0 },
                .{ .object_id = object_id_tree_lod1, .rank = 1 },
            },
            .default_variant_rank = 0,
            .feature_id = 1,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_tree,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 1024.0, .y = 512.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = null,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_tree,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 2048.0, .y = 2048.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = null,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_roads,
            .object_to_tile = null,
            .feature_id = 2,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
