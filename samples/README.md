# MLT 3D schema samples

Small, focused examples that demonstrate features of the 3D tile schema (`format_3d_schema.zig`). Each sample compiles with Zig and exposes a `tile: schema.MLT3DScene`. Buffer data is placeholder (empty); the schema describes structure and semantics only.

| Sample | Demonstrates |
|--------|--------------|
| **minimal.zig** | Bare structure: one primitive, one object, one instance. No features or textures. |
| **roads_tangent.zig** | 3D roads: `line_strip` with **normals** and **tangents** for flat ribbon extrusion. Primitive restart batches multiple road segments into one buffer. UV.x stores distance along the road. |
| **instancing.zig** | **Instancing**: one box object placed at three positions with different `object_to_tile` matrices (translation and rotation). |
| **features.zig** | **Feature properties**: building and road objects with typed name-value properties. Feature objects hold properties directly (no flat list scanning). |
| **scene_roads_trees.zig** | **Complex scene**: roads (tangent/normal) + trees (trunk + canopy), features, and day/night **themes** via per-primitive `theme_material_ids`. |
| **materials_pbr.zig** | **PBR material**: `base_color_texture`, `orm_texture` (R=Occlusion, G=Roughness, B=Metallic), `normal_map_texture`, scalar factors. |
| **bounding_volumes.zig** | **Bounding volumes**: box on primitive, sphere on object, pre-transformed box on instance for efficient tile-space culling. |
| **points.zig** | **Point topology**: points primitive with per-vertex `colors` (vec4u8). |
| **encoding.zig** | **Fixed vertex types and z_scale**: vec3i32 positions, vec3f32 normals, vec2u16 UVs. `z_scale` converts integer Z to meters. |
| **primitive_restart.zig** | **Primitive restart**: `triangle_strip` with `primitive_restart = true`; 0xFFFFFFFF separates strips in one index buffer. |
| **validate_tile.zig** | **Validation**: runs `validateTile(tile)` to catch common draft-time encoding mistakes. |
| **themes.zig** | **Themes**: day/night material switching via per-primitive `theme_material_ids`. The style sheet selects a material from the list; the default is used when no override is active. |
| **themes_mixed_textures.zig** | **Themes with mixed textures**: default material is untextured (flat color), theme alternate uses a `base_color_texture`. UVs are present in the vertex buffer even though the default material doesn't use them, so the textured theme renders correctly when selected. |
| **object_primitive_transforms.zig** | **Multi-primitive object**: tree with trunk and canopy as separate primitives, each with a different material, instanced at three positions. |

## Build

From the repository root, build all samples:

```bash
zig build
```

Executables are written to `zig-out/bin/` (e.g. `zig-out/bin/minimal`, `zig-out/bin/roads_tangent`). The root `build.zig` adds the `format_3d_schema` module so each sample can `@import("format_3d_schema")`.
