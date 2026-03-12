//! 3D roads: line-strip primitives with tangent semantics.
//!
//! The road centerline has a **tangent** at each vertex (direction along the line).
//! A renderer can use tangent (and optional **normal**, e.g. up) to extrude a band
//! into a 3D mesh. **A style sheet can supply width and thickness** (e.g. line-width,
//! extrusion) to control the road cross-section, similar to how MVT styles specify
//! line width for 2D roads.

const schema = @import("format_3d_schema");

const primitive_id_road: schema.PrimitiveId = 1;
const object_id_roads: schema.ObjectId = 1;
const material_id_road: schema.MaterialId = 1;

const primitive_road = schema.Primitive3D{
    .id = primitive_id_road,
    .name = "road_centerline",
    .topology = .line_strip,
    .material_id = material_id_road,
    .vertex_buffer = .{
        .indices = null,
        .positions = .{
            .position_type = .{ .shape = .vec3, .scalar = .f32 },
            .encoding = .none,
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{
            .{
                .id = 1,
                .name = null,
                .value_type = .{ .shape = .vec3, .scalar = .f32 },
                .encoding = .none,
                .scale = null,
                .element_count = 0,
                .data = &[_]u8{},
            },
        },
    },
};

const object_roads = schema.Object3D{
    .id = object_id_roads,
    .name = "roads",
    .primitive_instances = &[_]schema.PrimitiveInstance{
        .{ .primitive_id = primitive_id_road, .primitive_to_object = null },
    },
};

const material_road = schema.Material{
    .id = material_id_road,
    .name = "road",
    .textures = &[_]schema.Texture{},
    .attributes = &[_]schema.MaterialAttribute{
        .{ .id = 1, .name = "width", .value = .{ .scalar = .{ .f32 = 6.0 } } },
    },
};

pub const tile = schema.Tile3D{
    .extents = .{ .x = 4096, .y = 4096, .z = 256 },
    .features = &[_]schema.Feature{},
    .semantics = schema.TileSemantics{
        .vertex_attribute_semantics = &[_]schema.VertexAttributeSemanticBinding{
            .{ .primitive_id = primitive_id_road, .attribute_id = 1, .semantic = .tangent },
        },
        .texture_semantics = &[_]schema.TextureSemanticBinding{},
        .material_attribute_semantics = &[_]schema.MaterialAttributeSemanticBinding{},
    },
    .materials = &[_]schema.Material{material_road},
    .primitives = &[_]schema.Primitive3D{primitive_road},
    .objects = &[_]schema.Object3D{object_roads},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{
            .object_id = object_id_roads,
            .object_to_tile = null,
            .feature_id = null,
        } },
    },
};

pub fn main() void {
    _ = tile;
}
