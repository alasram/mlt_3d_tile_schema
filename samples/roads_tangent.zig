//! 3D roads: line_strip primitives with tangent and normal vertex attributes.
//!
//! The road centerline stores a tangent (direction along the line) and a normal
//! (up direction) at each vertex. A renderer can use these to extrude the polyline
//! into a 3D road mesh. A style sheet supplies width and thickness (e.g. line-width,
//! extrusion) to control the road cross-section, similar to how MVT styles specify
//! line width for 2D roads.
//!
//! For line_strip topology, both normals and tangents are optional. Without either, the renderer
//! may draw a basic stroke or compute an extrusion normal. With normals, tube extrusion is
//! possible. This sample provides both normals and tangents for full ribbon extrusion.
//! UV.x can represent distance along the road for road markings or dashed line textures.

const schema = @import("format_3d_schema");

const primitive_id_road: schema.PrimitiveId = 1;
const object_id_roads: schema.ObjectId = 1;
const material_id_road: schema.MaterialId = 1;

// line_strip: normals and tangents both provided here for full ribbon extrusion.
// primitive_restart = true allows multiple disconnected road segments in one buffer.
const primitive_road = schema.Primitive3D{
    .id = primitive_id_road,
    .topology = .line_strip,
    .material_id = material_id_road,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{
            .primitive_restart = true, // 0xFFFFFFFF separates road segments.
            .element_count = 0,
            .data = &[_]u8{},
        },
        .vertex_count = 0,
        .positions = &[_]u8{},
        // Normal: up direction (Z-up) for road mesh extrusion (enables tube extrusion).
        .normals = &[_]u8{},
        // Tangent: along-road direction for road width extrusion.
        .tangents = &[_]u8{},
        // UV.x: distance along road (for road markings, dashed lines). UV.y is ignored.
        .uvs = &[_]u8{},
    },
};

const object_roads = schema.Object3D{
    .id = object_id_roads,
    .name = "roads",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id_road},
};

const material_road = schema.Material{
    .id = material_id_road,
    .shading_model = .lambertian,
    .base_color_factor = .{ .x = 0.3, .y = 0.3, .z = 0.3, .w = 1.0 },
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material_road},
    .primitives = &[_]schema.Primitive3D{primitive_road},
    .objects = &[_]schema.Object3D{object_roads},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        .{ .object_id = object_id_roads },
    },
};

pub fn main() void {
    _ = tile;
}
