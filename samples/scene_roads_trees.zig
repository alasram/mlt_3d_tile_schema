//! Complex scene: roads and trees in one tile with features and themes.
//!
//! Roads: line_strip with normals and tangents for mesh extrusion.
//! Trees: trunk + canopy object instanced at three positions.
//! Features: per-instance properties for styling (type, road_class).
//! Themes: "day" and "night" appearance via per-primitive theme_material_ids.

const schema = @import("format_3d_schema");

const primitive_id_trunk: schema.PrimitiveId = 1;
const primitive_id_canopy: schema.PrimitiveId = 2;
const primitive_id_road: schema.PrimitiveId = 3;

const object_id_tree: schema.ObjectId = 1;
const object_id_roads: schema.ObjectId = 2;

const material_id_trunk_day: schema.MaterialId = 1;
const material_id_canopy_day: schema.MaterialId = 2;
const material_id_road_day: schema.MaterialId = 3;
const material_id_road_night: schema.MaterialId = 4;

// --- Primitives ---

const primitive_trunk = schema.Primitive3D{
    .id = primitive_id_trunk,
    .topology = .triangles,
    .material_id = material_id_trunk_day,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

const primitive_canopy = schema.Primitive3D{
    .id = primitive_id_canopy,
    .topology = .triangles,
    .material_id = material_id_canopy_day,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
    },
};

// Road: line_strip with normals and tangents required. Primitive restart allows
// multiple road segments in one buffer. Night material listed in theme_material_ids
// for style sheet selection.
const primitive_road = schema.Primitive3D{
    .id = primitive_id_road,
    .topology = .line_strip,
    .material_id = material_id_road_day,
    .theme_material_ids = &[_]schema.MaterialId{material_id_road_night},
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .primitive_restart = true,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .vertex_count = 0,
        .positions = &[_]u8{},
        .normals = &[_]u8{},
        .tangents = &[_]u8{},
    },
};

// --- Objects ---

const object_tree = schema.Object3D{
    .id = object_id_tree,
    .name = "tree",
    .primitive_ids = &[_]schema.PrimitiveId{ primitive_id_trunk, primitive_id_canopy },
};

const object_roads = schema.Object3D{
    .id = object_id_roads,
    .name = "roads",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_road},
};

// --- Materials ---

const material_trunk_day = schema.Material{
    .id = material_id_trunk_day,
    .name = "trunk_day",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.4, .y = 0.25, .z = 0.1, .w = 1.0 },
};

const material_canopy_day = schema.Material{
    .id = material_id_canopy_day,
    .name = "canopy_day",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.1, .y = 0.5, .z = 0.1, .w = 1.0 },
};

const material_road_day = schema.Material{
    .id = material_id_road_day,
    .name = "road_day",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.3, .y = 0.3, .z = 0.3, .w = 1.0 },
};

// Night road: darker surface with slight emissive for road markings.
const material_road_night = schema.Material{
    .id = material_id_road_night,
    .name = "road_night",
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.1, .y = 0.1, .z = 0.1, .w = 1.0 },
    .emissive_factor = .{ .x = 0.02, .y = 0.02, .z = 0.02 },
};

// --- Features ---

pub const features_list = &[_]schema.Feature{
    .{
        .id = 1,
        .properties = &[_]schema.FeatureProperty{
            .{ .name = "type", .value = .{ .string = "tree" } },
        },
    },
    .{
        .id = 2,
        .properties = &[_]schema.FeatureProperty{
            .{ .name = "type", .value = .{ .string = "road" } },
            .{ .name = "road_class", .value = .{ .string = "primary" } },
        },
    },
};

// --- Tile ---

pub const tile = schema.Tile3D{
    .extent = 4096,
    .materials = &[_]schema.Material{
        material_trunk_day,
        material_canopy_day,
        material_road_day,
        material_road_night,
    },
    .primitives = &[_]schema.Primitive3D{ primitive_trunk, primitive_canopy, primitive_road },
    .objects = &[_]schema.Object3D{ object_tree, object_roads },
    // Road primitive declares material_id_road_night in theme_material_ids; a style sheet
    // can select it for a night appearance. Trees have no theme alternates.
    .features = features_list,
    .scene = &[_]schema.ObjectInstance{
        // Tree at (512, 768, 0) with feature_id 1.
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 512, 768, 0, 1 },
            },
            .feature_id = 1,
        },
        // Tree at (1024, 512, 0).
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 1024, 512, 0, 1 },
            },
        },
        // Tree at (2048, 2048, 0).
        .{
            .object_id = object_id_tree,
            .object_to_tile = schema.Mat4x4f32{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 2048, 2048, 0, 1 },
            },
        },
        // Roads with feature_id 2.
        .{
            .object_id = object_id_roads,
            .feature_id = 2,
        },
    },
};

pub fn main() void {
    _ = tile;
}
