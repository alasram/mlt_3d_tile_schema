# MLT 3D Tile Schema (proposal / draft)

This repository contains a **draft 3D tile schema** intended to be used with **MapLibre Tile (MLT)** alongside **Mapbox Vector Tiles (MVT)**.

The goal is to propose what's required for a simple, useful 3D tile payload for maps, with an emphasis on:

- **Simplicity over completeness**: align with MVT's "one tile payload" model and keep the format small and understandable.
- **Geometry only, style-driven appearance**: the tile carries geometry and data; the style sheet controls all visual presentation (color, shading, opacity, etc.) — the same approach as MVT.
- **Fixed vertex types**: positions (`vec3i32`), optional banking angles (`i32` for line topologies), and optional custom vertex attributes (`i32` or `f32`). No generic attribute descriptors.
- **MVT-aligned features**: per-instance feature properties (name–value pairs) for styling, filtering, and labeling — the same mental model as MVT feature properties.
- **Asset Library**: shared assets (trees, poles, etc.) stored in external MLT files and referenced via an import table.

## What this is (and isn't)

This repo focuses on the **content schema of a single tile**.

- It **does** define the logical structure of a tile payload: scene, objects, primitives, fixed vertex buffers, features, custom attributes, and asset imports.
- It **does not** define a tileset / tile tree hierarchy (parent/child refinement, tileset JSON, etc.). Like MVT, the tile hierarchy is assumed to come from the map tiling system (zoom/x/y). Zoom-level tiling is the primary LOD mechanism.
- It **does not** define a concrete binary encoding. Buffers are raw bytes; compression is handled by the MLT encoding layer.
- It **does not** include materials, textures, normals, or intra-tile LOD. The style sheet controls all appearance.

## Design principles

- **MVT alignment**
  - Tiles are addressed by zoom/x/y externally (same map tile addressing as MVT).
  - A single integer `extent` (like MVT) defines the coordinate range for X and Y. Z uses the same unit.
  - `z_scale` converts integer Z values to meters.
  - The coordinate system is left-handed with Z-up: X right (East), Y down (South), Z up.
  - Object3D names correspond to MVT layer names for style sheet targeting and 2D/3D correlation.

- **Flat scene**
  - The tile scene is a flat list of `ObjectInstance` values. No scene graph, no LOD groups.

- **Fixed vertex types**
  - Positions: `vec3i32` (required). Banking angles: `i32` (optional, line topologies only).
  - Custom vertex attributes: named arrays of `i32` or `f32` values for data-driven styling.
  - All integers use i32/u32 unless MVT interop requires otherwise (e.g. i64 for feature property integers).
  - Data is stored as-is. No delta encoding. Binary compression is the encoding layer's responsibility.

- **Style-driven appearance**
  - The tile carries no materials, textures, or normals. The style sheet controls all visual presentation.
  - Custom vertex attributes let producers encode data values (e.g. temperature, elevation) that the style sheet maps to visual properties.

- **Styling-oriented features**
  - Each `ObjectInstance` has an optional `feature_id` linking to a `Feature` with name–value properties, identical to MVT feature properties.

- **Asset Library**
  - Shared assets are stored in external MLT files. The import table maps each external primitive to a local PrimitiveId. The style sheet declares Asset Libraries (mapping names to URLs).

## Repository layout

- `format_3d_schema.zig`
  - The draft schema definition (main artifact).
- `format_3d_comparison.md`
  - Comparison of this schema with other 3D geospatial formats (3D Tiles, I3S, CityJSON, COPC, glTF, etc.).
- `samples/`
  - Small Zig programs that construct example `schema.MLT3DScene` values demonstrating specific features.
  - See `samples/README.md` for a table of included samples.
- `build.zig`
  - Zig build file that builds all samples.

## Schema overview

At a high level (see `format_3d_schema.zig`):

- A `MLT3DScene` contains:
  - `extent`: single integer defining the coordinate range (like MVT extent).
  - `z_scale`: converts integer Z values to meters.
  - `primitives`: geometry units (topology + vertex buffer).
  - `imports`: import table for referencing primitives from external Asset Libraries.
  - `objects`: named collections of primitive IDs (name is required, corresponds to MVT layer name).
  - `features`: per-object name–value properties for styling.
  - `scene`: flat list of `ObjectInstance` entries.

- Geometry is expressed as:
  - `Primitive3D` (topology + vertex buffer).
  - `VertexBuffer` has: `positions` (required), `indices` (optional), optional `banking_angles` (line topologies), and optional `custom_attributes`.
  - All buffers are raw bytes stored as-is.

- Instances:
  - `ObjectInstance` places an `Object3D` into tile space via a `?Mat4x4f32`. Multiple instances may reference the same object at different transforms. Each instance has an optional `feature_id`.

## Build / run samples

You can build all samples from the repository root:

```bash
zig build
```

Executables are written to `zig-out/bin/` (for example `zig-out/bin/minimal`).

## Status

This is a **proposal / draft schema**.

- The schema is expressed in Zig types to be concrete and easy to validate.
- Encoding details (final binary layout, compression, etc.) are intentionally left open.

## Contributing

Issues and PRs are welcome.

If you propose changes, it helps to include:

- Motivation (what map/rendering/styling problem it solves)
- Any impact on simplicity and MVT-alignment
- A new or updated sample under `samples/`
