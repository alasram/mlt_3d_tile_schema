//! Lightweight tile validation.
//!
//! This sample demonstrates draft-time validation checks that catch common encoding mistakes.

const std = @import("std");
const schema = @import("format_3d_schema");

const ValidationError = error{
    InvalidBaseColorTextureKind,
    InvalidOrmTextureKind,
    InvalidNormalMapTextureKind,
    InvalidEmissiveTextureKind,
};

fn validateTile(t: *const schema.MLT3DScene) ValidationError!void {
    for (t.materials) |m| {
        if (m.base_color_texture) |tex| {
            if (tex.kind != .base_color) return error.InvalidBaseColorTextureKind;
        }
        if (m.orm_texture) |tex| {
            if (tex.kind != .orm) return error.InvalidOrmTextureKind;
        }
        if (m.normal_map_texture) |tex| {
            if (tex.kind != .normal_map) return error.InvalidNormalMapTextureKind;
        }
        if (m.emissive_texture) |tex| {
            if (tex.kind != .emissive) return error.InvalidEmissiveTextureKind;
        }
    }
}

const material_id: schema.MaterialId = 1;
const primitive_id: schema.PrimitiveId = 1;
const object_id: schema.ObjectId = 1;

const material = schema.Material{
    .id = material_id,
    .shading_model = .lambertian,
    .base_color_texture = schema.Texture{
        .kind = .base_color,
        .data = .{ .url = "file://facade.png" },
    },
};

const primitive = schema.Primitive3D{
    .id = primitive_id,
    .topology = .triangles,
    .material_id = material_id,
    .vertex_buffer = .{
        .indices = schema.IndexBuffer{ .element_count = 0, .data = &[_]u8{} },
        .vertex_count = 0,
        .positions = &[_]u8{},
        .uvs = &[_]u8{},
    },
};

const object = schema.Object3D{
    .id = object_id,
    .name = "mesh",
    .primitive_ids = &[_]schema.PrimitiveId{primitive_id},
};

pub const tile = schema.MLT3DScene{
    .extent = 4096,
    .z_scale = 1.0,
    .materials = &[_]schema.Material{material},
    .primitives = &[_]schema.Primitive3D{primitive},
    .objects = &[_]schema.Object3D{object},
    .features = &[_]schema.Feature{},
    .scene = &[_]schema.ObjectInstance{
        .{ .object_id = object_id },
    },
};

pub fn main() !void {
    validateTile(&tile) catch |err| {
        std.debug.print("validateTile failed: {}\n", .{err});
        return err;
    };
}
