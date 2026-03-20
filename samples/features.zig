//! Objects with different feature properties: styling and filtering.
//!
//! Each ObjectInstance has a feature_id. A Feature holds a direct list of
//! name-value properties. A styling tool can use these to drive color, filter
//! visibility, or labels (e.g. by type, height, road_class), similar to MVT
//! feature properties.

const schema = @import("format_3d_schema");

const primitive_id_building: schema.PrimitiveId = 1;
const primitive_id_road: schema.PrimitiveId = 2;
const object_id_building: schema.ObjectId = 1;
const object_id_road: schema.ObjectId = 2;
const material_id: schema.MaterialId = 1;

const primitive_building = schema.Primitive3D{
    .id = primitive_id_building,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

// Road: line_strip with normals and tangents for ribbon extrusion (both optional).
const primitive_road = schema.Primitive3D{
    .id = primitive_id_road,
    .topology = .line_strip,
    .material_id = material_id,
    .vertex_buffer = .{
        .vertex_count = 0,
        .positions = &[_]u8{},
        .normals = &[_]u8{},
        .tangents = &[_]u8{},
    },
};

const object_building = schema.Object3D{
    .id = object_id_building,
    .name = "building",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_building},
};

const object_road = schema.Object3D{
    .id = object_id_road,
    .name = "road",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_road},
};

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
};

// feature 1 = building (type, height_m); feature 2 = road (type, road_class, surface)
pub const features_list = &[_]schema.Feature{
    .{
        .id = 1,
        .properties = &[_]schema.FeatureProperty{
            .{ .name = "type", .value = .{ .string = "building" } },
            .{ .name = "height_m", .value = .{ .float = 12.0 } },
        },
    },
    .{
        .id = 2,
        .properties = &[_]schema.FeatureProperty{
            .{ .name = "type", .value = .{ .string = "road" } },
            .{ .name = "road_class", .value = .{ .string = "primary" } },
            .{ .name = "surface", .value = .{ .string = "asphalt" } },
        },
    },
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{ primitive_building, primitive_road },
    .objects = &[_]schema.Object3D{ object_building, object_road },
    .features = features_list,
    .scene = &[_]schema.ObjectInstance{
        .{
            .object_id = object_id_building,
            // Translate to (256, 512, 0) in tile space.
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 256 },
                .{ 0, 1, 0, 512 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
            .feature_id = 1,
        },
        .{
            .object_id = object_id_road,
            .feature_id = 2,
        },
    },
};

pub fn main() void {
    _ = tile;
}
