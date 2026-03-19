# MLT 3D Tile Schema (proposal / draft)

This repository contains a **draft 3D tile schema** intended to be used with **MapLibre Tile (MLT)** alongside **Mapbox Vector Tiles (MVT)**.

The goal is to propose what's required for a simple, useful 3D tile payload for maps, with an emphasis on:

- **Simplicity over completeness**: align with MVT's "one tile payload" model and keep the format small and understandable.
- **Fixed vertex attributes**: no generic attribute descriptors. Positions, UVs, normals, tangents, and colors have fixed types — a strict subset of glTF 2.0 vertex attributes.
- **Fixed material model**: a minimal PBR material (base color, ORM, normal map, emissive) with an optional simpler Lambertian shading mode. No generic attribute lists or semantic bindings.
- **MVT-aligned features**: per-instance feature properties (name–value pairs) for styling, filtering, and labeling — the same mental model as MVT feature properties.
- **Themes**: named sets of material overrides for scene-wide appearance switching (e.g. day/night) without duplicating geometry.

## What this is (and isn't)

This repo focuses on the **content schema of a single tile**.

- It **does** define the logical structure of a tile payload: scene, objects, primitives, fixed vertex buffers, materials, features, bounding volumes, and optional themes.
- It **does not** define a tileset / tile tree hierarchy (parent/child refinement, tileset JSON, etc.). Like MVT, the tile hierarchy is assumed to come from the map tiling system (zoom/x/y). Zoom-level tiling is the primary LOD mechanism.
- It **does not** define a concrete binary encoding. Buffers are raw bytes; compression is handled by the MLT encoding layer.
- It **does not** include intra-tile LOD groups. This is deferred to a future extension.

## Design principles

- **MVT alignment**
  - Tiles are addressed by zoom/x/y externally (same map tile addressing as MVT).
  - A single integer `extent` (like MVT) defines the coordinate range for X and Y. Z uses the same unit; an optional `z_scale` converts Z to meters.
  - The coordinate system is left-handed with Z-up: X right (East), Y down (South), Z up.

- **Flat scene**
  - The tile scene is a flat list of `ObjectInstance` values. No scene graph, no LOD groups.

- **Fixed vertex types**
  - Positions: `vec3i32`. UVs: `vec2u16`. Normals: `vec3f32`. Tangents: `vec4f32`. Colors: `vec4u8`.
  - Data is stored as-is. No delta encoding. Binary compression is the encoding layer's responsibility.

- **Fixed material model**
  - Materials have named texture slots (base color, ORM, normal map, emissive) and scalar PBR factors.
  - Two shading models: `lambertian` (simple diffuse) and `pbr` (glTF 2.0 metallic-roughness).

- **Styling-oriented features**
  - Each `ObjectInstance` has an optional `feature_id` linking to a `Feature` with a list of name–value properties, conceptually identical to MVT feature properties.

- **Themes**
  - Each `Primitive3D` declares a default `material_id` and an optional list of `theme_material_ids`. A style sheet selects which material is active per primitive, enabling scene-wide appearance switching (e.g. day/night) without duplicating geometry or adding a separate theme structure.

## Repository layout

- `format_3d_schema.zig`
  - The draft schema definition (main artifact).
- `format_3d_comparison.md`
  - Comparison of this schema with other 3D geospatial formats (3D Tiles, I3S, CityJSON, COPC, glTF, etc.).
- `samples/`
  - Small Zig programs that construct example `schema.Tile3D` values demonstrating specific features.
  - See `samples/README.md` for a table of included samples.
- `build.zig`
  - Zig build file that builds all samples.

## Schema overview

At a high level (see `format_3d_schema.zig`):

- A `Tile3D` contains:
  - `extent`: single integer defining the coordinate range (like MVT extent).
  - Optional `z_scale`: converts integer Z values to meters.
  - `materials`: global pool referenced by ID from primitives.
  - `primitives`, `objects`: geometry and groupings. Each primitive carries a default material and optional alternate theme materials.
  - `features`: per-object name–value properties for styling.
  - `scene`: flat list of `ObjectInstance` entries.

- Geometry is expressed as:
  - `Primitive3D` (topology + vertex buffer + default `material_id` + optional `theme_material_ids` list).
  - `VertexBuffer` has fixed named fields: `positions` (required), `indices` (optional), and optional `uvs`, `normals`, `tangents`, `colors`.
  - All buffers are raw bytes stored as-is.

- Instances:
  - `ObjectInstance` places an `Object3D` into tile space via a `?Mat4x4f32`. Multiple instances may reference the same object at different transforms.

- Materials:
  - `Material` has a `shading_model` (lambertian or pbr), four named optional texture slots, and scalar PBR factors.

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
