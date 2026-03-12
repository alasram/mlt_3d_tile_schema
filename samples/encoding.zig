//! Buffer encoding: Scale, delta encoding, and normalized attributes.
//!
//! Positions: integer (i16), delta-from-first encoding, scale factor to convert to float
//! (e.g. millimeters to world units). Vertex attributes: normalized integers (e.g. i8
//! signed normalized for normals, u16 unsigned normalized for UVs).

const schema = @import("format_3d_schema");

const scale_i16_position: f64 = 0.001; // e.g. millimeters -> world units

const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;
const material_id: schema.MaterialId = 1;

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .name = "mesh",
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
            .position_type = .{ .shape = .vec3, .scalar = .i16 },
            .encoding = .from_first,
            .scale = schema.Scale{
                .factor = .{ .f64 = scale_i16_position },
                .order = .scale_before_normalization,
            },
            .element_count = 0,
            .data = &[_]u8{},
        },
        .attributes = &[_]schema.VertexAttribute{
            .{
                .id = 1,
                .name = null,
                .value_type = .{ .shape = .vec3, .scalar = .i8, .normalization = .normalized_signed },
                .encoding = .from_first,
                .scale = null,
                .element_count = 0,
                .data = &[_]u8{},
            },
            .{
                .id = 2,
                .name = null,
                .value_type = .{ .shape = .vec2, .scalar = .u16, .normalization = .normalized_unsigned },
                .encoding = .none,
                .scale = null,
                .element_count = 0,
                .data = &[_]u8{},
            },
        },
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "mesh",
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
    .features = &[_]schema.Feature{},
    .semantics = null,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive},
    .objects = &[_]schema.Object3D{object},
    .scene = &[_]schema.SceneItem{
        .{ .object = schema.ObjectInstance{ .object_id = object_id, .object_to_tile = null, .feature_id = null } },
    },
};

pub fn main() void {
    _ = tile;
}
