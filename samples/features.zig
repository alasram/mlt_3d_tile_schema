//! Objects with different feature properties: styling and filtering.
//!
//! Each scene item can have a feature_id. Features are a list of (feature_id, name, value)
//! properties. A styling tool can use these to drive color, filter visibility, or labels
//! (e.g. by type, height, road_class), similar to MVT feature properties.

const schema = @import("format_3d_schema");

const primitive_id_building: schema.PrimitiveId = 1;
const primitive_id_road: schema.PrimitiveId = 2;
const object_id_building: schema.ObjectId = 1;
const object_id_road: schema.ObjectId = 2;
const material_id: schema.MaterialId = 1;

fn make_primitive(id: schema.PrimitiveId, name: []const u8, topology: schema.Topology) schema.Primitive3D {
    return schema.Primitive3D{
        .id = id,
        .name = name,
        .topology = topology,
        .material_id = material_id,
        .vertex_buffer = .{
            .indices = if (topology == .triangles) schema.IndexBuffer{
                .index_type = .u16,
                .encoding = .none,
                .element_count = 0,
                .data = &[_]u8{},
            } else null,
            .positions = .{
                .position_type = .{ .shape = .vec3, .scalar = .f32 },
                .encoding = .none,
                .element_count = 0,
                .data = &[_]u8{},
            },
            .attributes = &[_]schema.VertexAttribute{},
        },
    };
}

const primitive_building = make_primitive(primitive_id_building, "building", .triangles);
const primitive_road = make_primitive(primitive_id_road, "road", .line_strip);

const object_building = schema.Object3D{
    .id = object_id_building,
    .name = "building",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_building, .primitive_to_object = null },
    },
};

const object_road = schema.Object3D{
    .id = object_id_road,
    .name = "road",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_road, .primitive_to_object = null },
    },
};

const material = schema.Material{
    .id = material_id,
    .name = "default",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{},
};

// feature_id 1 = building (height_m, type); feature_id 2 = road (road_class, surface)
pub const features_list = &[_]schema.Feature{
    .{ .feature_id = 1, .name = "type", .value = .{ .string = "building" } },
    .{ .feature_id = 1, .name = "height_m", .value = .{ .scalar = .{ .f32 = 12.0 } } },
    .{ .feature_id = 2, .name = "type", .value = .{ .string = "road" } },
    .{ .feature_id = 2, .name = "road_class", .value = .{ .string = "primary" } },
    .{ .feature_id = 2, .name = "surface", .value = .{ .string = "asphalt" } },
};

pub const tile = schema.Tile3D{
    .extents = .{ .x = 4096, .y = 4096, .z = 256 },
    .features = features_list,
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{ primitive_building, primitive_road },
    .objects = &[_]schema.Object3D{ object_building, object_road },
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_building,
            .object_to_tile = schema.Transform{ .pose_f64 = .{
                .location = .{ .x = 256.0, .y = 512.0, .z = 0.0 },
                .orientation = .{ .euler = .{ .roll = 0.0, .pitch = 0.0, .yaw = 0.0 } },
            } },
            .feature_id = 1,
        } },
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_road,
            .object_to_tile = null,
            .feature_id = 2,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
