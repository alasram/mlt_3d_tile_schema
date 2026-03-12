# MLT 3D schema samples

Small, focused examples that demonstrate features of the 3D tile schema (`format_3d_schema.zig`). Each sample compiles with Zig and exposes a `tile: schema.Tile3D` (and optionally other exports). Buffer data is placeholder (empty); the schema describes structure and semantics only.

| Sample | Demonstrates |
|--------|--------------|
| **minimal.zig** | Bare structure: one primitive, one object, one instance. No semantics or features. |
| **roads_tangent.zig** | 3D roads: line-strip with **tangent** semantic. Comment explains that a style sheet can add width and thickness (like MVT line-width). |
| **instancing.zig** | **Instancing**: one simple shape (box) placed multiple times with different `object_to_tile` transforms. |
| **features.zig** | **Objects with different feature properties**: building (type, height_m) and road (type, road_class, surface). Styling tools can use these. |
| **scene_roads_trees.zig** | **Complex scene**: roads (tangent semantic) + trees (trunk + canopy, instanced; one LOD group). Features for tree and road. |
| **lod.zig** | **LOD**: one LodGroupInstance with two variants (detailed vs simple), geometric_error on tile and variant. |
| **materials_pbr.zig** | **PBR semantics**: texture and material-attribute bindings (base color, metallic, roughness, normal, texcoord). |
| **bounding_volumes.zig** | **Bounding volumes** (box on primitive, sphere on object) and **geometric_error** on tile. |
| **points.zig** | **Point topology**: points primitive with color_0 semantic. |
| **encoding.zig** | **Buffer encoding**: Scale on positions (i16, factor), delta encoding (from_first), normalized vertex attributes (e.g. normals, UVs). |
| **primitive_restart.zig** | **Triangle strip with primitive restart**: IndexBuffer.primitive_restart = true for multiple strips in one buffer. |
| **strided_positions.zig** | **Strided positions**: positions buffer with element_stride (e.g. padded or interleaved layout). |
| **object_primitive_transforms.zig** | **Object with primitive transforms**: multiple primitives per object with non-identity primitive_to_object (matrix and pose). |

## Build

From the repository root, build all samples:

```bash
zig build
```

Executables are written to `zig-out/bin/` (e.g. `zig-out/bin/minimal`, `zig-out/bin/roads_tangent`). The root `build.zig` adds the `format_3d_schema` module so each sample can `@import("format_3d_schema")`.
