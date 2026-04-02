# MLT 3D schema samples

Small, focused examples that demonstrate features of the 3D tile schema (`format_3d_schema.zig`). Each sample compiles with Zig and constructs an `MLT3DScene` value. Buffer data is placeholder (zeroed); the schema describes structure and semantics only.

The tile carries geometry and data only — the style sheet controls all visual appearance (color, shading, opacity, etc.), just like MVT.

| Sample | Demonstrates |
|--------|--------------|
| **minimal.zig** | Bare structure: one triangle primitive, one object, one instance. No features or custom attributes. |
| **instancing.zig** | **Instancing**: one tree object (trunk + canopy) placed at three positions with different `object_to_tile` matrices. |
| **features.zig** | **Feature properties**: building and road objects with typed name-value properties (matching the MVT property model). |
| **points.zig** | **Point topology**: points primitive for labels/icons. Style sheet controls appearance via feature properties. |
| **primitive_restart.zig** | **Primitive restart**: `triangle_strip` with `primitive_restart = true`; 0xFFFFFFFF separates strips in one index buffer. |
| **banking_angle.zig** | **Banking angle**: `line_strip` road with per-vertex banking angles (tenths of a degree) for tilted road ribbons. |
| **custom_attributes.zig** | **Custom vertex attributes**: per-vertex `temperature` (f32) and `elevation` (i32) values that the style sheet maps to visual properties. |
| **asset_library.zig** | **Asset Library**: importing shared tree primitives from an external Asset Library via the import table, mixed with local primitives. |
| **scene_roads_trees.zig** | **Combined scene**: roads with banking angles + trees via instancing, multiple object types and features in one tile. |

## Build

From the repository root, build all samples:

```bash
zig build
```

Executables are written to `zig-out/bin/`. The root `build.zig` adds the `format_3d_schema` module so each sample can `@import("format_3d_schema")`.
