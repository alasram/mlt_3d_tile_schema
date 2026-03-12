# MLT 3D Tile Schema (proposal / draft)

This repository contains a **draft 3D tile schema** intended to be used with **MapLibre Tile (MLT)** alongside **Mapbox Vector Tiles (MVT)**.

The goal is to propose what’s required for a *good* 3D tile payload for maps, with an emphasis on:

- **Simplicity over completeness**: align with MVT’s “one tile payload” model and keep the format small and understandable.
- **Renderer-agnostic core**: define *what the data means* (schema) rather than mandating a final binary encoding.
- **Generic attributes + optional semantics**: support custom per-feature and per-vertex attributes, while allowing optional well-known semantics so renderers can interoperate.
- **glTF-friendly rendering**: reuse glTF 2.0 conventions for transforms and (optionally) PBR semantics so a glTF-capable renderer can support this with minimal special casing.

## What this is (and isn’t)

This repo focuses on the **content schema of a single tile**.

- It **does** define the logical structure of a tile payload (scene items, objects, primitives, materials, attributes, features, optional LOD and bounding volumes).
- It **does not** define a tileset / tile tree hierarchy (parent/child refinement, tileset JSON, etc.). Like MVT, the tile hierarchy is assumed to come from the map tiling system (zoom/x/y).
- It **does not** define a concrete binary encoding yet; buffers are represented as raw bytes with type/stride/encoding metadata.

## Design principles

- **MVT alignment**
  - Tiles are addressed by zoom/x/y externally (same map tile addressing as MVT).
  - Tile-local coordinate units are intended to be **MVT extent aligned** for X/Y, and **Z uses the same unit system** to keep 2D/3D alignment (e.g. extrusions) consistent.

- **Flat scene**
  - The tile scene is a flat list of instances (`ObjectInstance` / `LodGroupInstance`) rather than a nested scene graph.

- **Styling-oriented features**
  - Optional per-instance `feature_id` links to a `features` table of name–value properties, conceptually similar to MVT feature properties.

- **Optional semantics for interop**
  - `TileSemantics` can bind well-known meanings (e.g. PBR textures/material attributes, vertex normals/tangents/UVs/colors).
  - When semantics are present, a renderer can treat the tile similarly to glTF 2.0 for default shading.

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
  - `extents`: tile dimensions in MVT-aligned extent units.
  - Optional `geometric_error`.
  - Optional `semantics` (`TileSemantics`).
  - Optional `features` (name–value properties addressed by `feature_id`).
  - `materials`, `primitives`, `objects`.
  - `scene`: a flat list of `SceneItem` entries.

- Geometry is expressed as:
  - `Primitive3D` (topology + vertex buffer + optional material).
  - `VertexBuffer` contains positions, optional indices, and optional per-vertex attributes.
  - Buffers carry metadata for element type, optional delta encoding, optional stride, and optional integer scaling/normalization.

- Instances:
  - `ObjectInstance` places an `Object3D` into tile space.
  - `LodGroupInstance` places a set of LOD variants into tile space; variant selection is client-defined.

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
- How it would map to / from glTF 2.0 semantics (if relevant)
- A new or updated sample under `samples/`
