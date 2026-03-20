# Comparison: MLT 3D Tile Schema with Other Map 3D Formats

This document compares the **MLT 3D tile schema** (draft), as defined in `format_3d_schema.zig`, with other formats commonly used for 3D and map content. The MLT 3D schema is designed for use with MapLibre Tile (MLT), alongside MVT, to support 2D+3D tile-based rendering in maps.

**Important:** The draft schema is **limited to one tile** (one payload per zoom/x/y), the same as MVT. When comparing to formats that support a hierarchical structure (e.g. 3D Tiles, I3S), note that **maps are usually composed of a hierarchy of tiles**—multiple zoom levels, spatial subdivision, LOD refinement—but that hierarchy is **outside** this schema: it is defined by the map/tileset (e.g. how the client requests tiles by zoom/x/y). This schema describes only the content of a single tile, not the tile tree or how tiles relate across the map.

---

## Summary Table

| Aspect | MLT 3D (this schema) | 3D Tiles (Cesium) | I3S (Esri/OGC) | OGC 3DPS | CityGML / CityJSON | COPC |
|--------|----------------------|-------------------|----------------|----------|--------------------|------|
| **Primary focus** | Single-tile 3D payload for MLT | Streaming 3D geospatial tiles | Scene layers (buildings, mesh, point clouds) | Service API for 3D delivery | 3D city model data model | Point clouds only |
| **Tile structure** | One tile per payload (zoom/x/y, MVT-aligned) | Tileset + tile tree, spatial hierarchy | Node tree, level-of-detail | Service defines delivery | N/A (full dataset or region) | Single file, internal octree |
| **Geometry** | Primitives + vertex buffers (glTF-like) | b3dm, i3dm, pnts, glTF, composite | Geometry per node, mesh/point | Format-agnostic | Boundary representation, surfaces | LAS/LAZ points, octree |
| **LOD** | Zoom-level tiling (external); no intra-tile LOD | Per-tile refinement, geometric error | Node tree LOD | By service | N/A or application-defined | Octree hierarchy |
| **Features / styling** | First-class features + feature_id | Batch table, feature IDs | Attributes per feature | By content format | CityGML semantics, CityJSON attrs | Point attributes (LAS) |
| **CRS / anchoring** | Not defined (local tile coords, MVT structure) | WGS 84, bounding volumes | Geographic | Service / content | Often CRS in metadata | LAS header (coordinates) |
| **Materials** | Fixed model: base_color / ORM / normal_map / emissive; Lambertian or PBR shading | glTF materials, legacy in b3dm | Per-layer / per-node | By content | Appearance (textures, materials) | N/A (point color/intensity) |
| **Standardization** | Draft, MLT community | Cesium/OGC 3D Tiles | OGC I3S | OGC 3DPS | OGC CityGML, OGC CityJSON | Community (COPC 1.0) |

---

## 1. 3D Tiles (Cesium / OGC)

**Role:** Streaming massive 3D geospatial datasets with a tile tree, multiple tile formats, and refinement by geometric error.

### Comparison

- **Tile model**
  - **3D Tiles:** A *tileset* (e.g. `tileset.json`) defines a tree of tiles. Each tile has a bounding volume, geometric error, and content (e.g. glTF, b3dm, i3dm, pnts, or composite). Tiles are loaded based on view and refinement. The **tile hierarchy** (parent/child, refinement) is part of the format.
  - **MLT 3D:** A *single tile* is one payload (like one MVT tile). The schema does **not** define a tile hierarchy; the map is composed of many such tiles requested by zoom/x/y (as with MVT). Zoom-level tiling is the primary LOD mechanism; intra-tile LOD is deferred to a future extension.

- **Content formats**
  - **3D Tiles:** Supports multiple payload types: Batched 3D Model (b3dm, deprecated in 1.1), Instanced 3D Model (i3dm), Point Cloud (pnts), and **glTF** (e.g. 3DTILES_content_gltf). Composite tiles reference other tiles.
  - **MLT 3D:** One logical schema per tile: primitives, materials, objects, scene. Geometry and materials align with glTF 2.0 conventions; no separate b3dm/i3dm/pnts.

- **Features**
  - **3D Tiles:** Batch table (or metadata) with feature IDs; instances or batches map to feature properties.
  - **MLT 3D:** Explicit `features` array and `feature_id` on object instances; styling-oriented properties (name–value), similar in spirit to MVT feature properties.

- **Use case**
  - **3D Tiles:** Global or large-area 3D streaming (e.g. Cesium), view-dependent refinement, multiple formats in one ecosystem.
  - **MLT 3D:** One tile for a given zoom/x/y, to be used like MVT in a map stack (e.g. MapLibre), with optional PBR and styling.

### Conversion

- **3D Tiles → MLT 3D:** Per tile, extract content (e.g. one glTF or one b3dm's glTF). Map tile bounds to the `extent`. Flatten the tile's scene into objects and a flat scene list; map batch/feature table to `features` and `feature_id`.
- **MLT 3D → 3D Tiles:** Emit a tileset with one (or more) tiles; each MLT 3D tile becomes one 3D Tiles tile. Content can be glTF or a 3D Tiles payload that wraps the same geometry. Bounding volumes map across.

---

## 2. I3S (Indexed 3D Scene Layers, Esri / OGC)

**Role:** Scene layers for 3D GIS: buildings, 3D objects, integrated meshes, point clouds. Tree of nodes with geometry and attributes, optimized for streaming.

### Comparison

- **Structure**
  - **I3S:** Node tree; each node can have geometry, textures, and attributes. Layer type (e.g. 3D Object, Integrated Mesh, Point) determines schema. SLPK (Scene Layer Package) for file-based distribution.
  - **MLT 3D:** Flat scene list of object instances; no node tree. Objects reference primitives and materials from a global pool. Zoom-level tiling handles LOD externally; no intra-tile LOD groups.

- **Geometry**
  - **I3S:** Geometry and attributes are layer-type specific (e.g. mesh with UVs, normals; point with position, color). Often optimized for Esri runtimes.
  - **MLT 3D:** Fixed vertex types (vec3i32 positions, vec2u16 UVs, vec3f32 normals, vec4f32 tangents, vec4u8 colors), glTF 2.0 topology. Fixed material model: base_color, ORM, normal_map, emissive texture slots + Lambertian or PBR shading.

- **Features / attributes**
  - **I3S:** Per-node or per-feature attributes; used for popups, filtering, and styling in ArcGIS.
  - **MLT 3D:** Per-instance `feature_id` and a global `features` list with name–value properties for styling tools (MVT-like).

- **Tile / LOD**
  - **I3S:** Hierarchical nodes; levels of detail and spatial indexing are part of the layer structure (the format describes the hierarchy).
  - **MLT 3D:** One tile per payload (MVT-style); the **tile hierarchy** (many tiles making up the map) is outside the schema. Zoom-level tiling is the primary LOD mechanism; no intra-tile LOD.

### Conversion

- **I3S → MLT 3D:** For a given I3S node (or set of nodes), export geometry as primitives and materials. Map node attributes to `features` and attach via `feature_id`. Flatten node hierarchy into object instances.
- **MLT 3D → I3S:** One MLT 3D tile could become one or more I3S nodes; object instances become nodes. I3S layer type and attribute schema would need to be chosen (e.g. 3D Object).

---

## 3. OGC 3D Portrayal Service (3DPS)

**Role:** OGC standard that specifies *how* 3D content is described, selected, and delivered (View and Scene conformance). It does **not** define a single content format.

### Comparison

- **Scope**
  - **3DPS:** Service interface and portrayal model (e.g. what to request, how to describe 3D content). Content can be 3D Tiles, I3S, or other formats.
  - **MLT 3D:** A **content schema** for one tile payload. Delivery (HTTP, caching, zoom/x/y) is defined by MLT / MVT-style tiling, not by 3DPS.

- **Relationship**
  - **MLT 3D** could be used as one of the content formats delivered by a 3DPS-compliant service. The schema describes the structure of a tile; 3DPS would describe how clients request and receive such tiles (e.g. by region, LOD, style).

- **Conformance**
  - **3DPS:** View (image-based) vs Scene (scene graph–based) conformance. MLT 3D is scene-oriented (objects, primitives, materials) but with a flat scene list, so it fits the Scene side rather than pre-rendered views.

### Conversion

- No direct "conversion" between 3DPS and MLT 3D: 3DPS is a service standard. A server could expose MLT 3D tiles via a 3DPS Scene interface; clients would consume MLT 3D as the payload format.

---

## 4. CityGML / CityJSON

**Role:** 3D city and landscape models: buildings, roads, vegetation, etc., with rich semantics (building parts, surfaces, thematic types). CityJSON is a JSON encoding of a CityGML subset.

### Comparison

- **Data model**
  - **CityGML / CityJSON:** Thematic modules (Building, Road, Vegetation, etc.), boundary representation (surfaces, solids), appearance (materials, textures), and semantic attributes (e.g. building function, roof type).
  - **MLT 3D:** Generic primitives, materials, and objects; no built-in city semantics. Semantic meaning can be carried in **features** (e.g. "building", "road_type") for styling.

- **Geometry**
  - **CityGML / CityJSON:** Surfaces and solids (boundary rep); coordinates in a CRS; often one large dataset or region.
  - **MLT 3D:** Triangle (or line/point) primitives in **local tile coordinates**; no CRS in schema. One tile per zoom/x/y.

- **Tiling**
  - **CityGML / CityJSON:** Typically not tile-based; datasets are city- or region-sized. Tiling can be applied at ingestion (e.g. split by tile and export to MLT 3D).
  - **MLT 3D:** Designed for tile-based delivery (MVT-style).

- **Styling**
  - **CityGML / CityJSON:** Thematic and semantic attributes drive styling in applications; CityJSON has optional appearance.
  - **MLT 3D:** Styling via **features** (name–value properties); theme appearance switching via per-primitive `theme_material_ids` selectable by a style sheet. Styling tools can use feature properties like in MVT.

### Conversion

- **CityGML/CityJSON → MLT 3D:** For each tile (zoom/x/y), select city objects that intersect the tile. Tessellate surfaces into triangles; map to primitives and materials. Export CityObject attributes as `features` and link via `feature_id`. Transform coordinates to local tile space.
- **MLT 3D → CityGML/CityJSON:** Possible but lossy: primitives become geometry; features could map to CityJSON attributes. Semantics (e.g. Building, Road) would need to be inferred or stored in feature names/values.

---

## 5. Cloud Optimized Point Clouds (COPC)

**Role:** Single-file, cloud-friendly point cloud format (LAS/LAZ with an internal octree). Range-readable for spatial queries.

### Comparison

- **Content type**
  - **COPC:** **Point clouds only** (LAS Point Data Record Formats 6, 7, or 8). Octree inside one file; VLRs for hierarchy and metadata.
  - **MLT 3D:** Meshes, lines, points. Primitives can be points (`Topology.points`), but the schema also supports triangles and lines; not specialized for point clouds.

- **Organization**
  - **COPC:** One file, octree, range requests for subregions. No zoom/x/y tile grid in the format.
  - **MLT 3D:** One tile per payload (zoom/x/y); points in a tile would be one or more point primitives with positions and optional attributes (e.g. color, classification).

- **Use case**
  - **COPC:** Large point clouds (e.g. lidar), cloud storage, spatial subsetting without full download.
  - **MLT 3D:** Mixed 2D/3D map tiles (MVT + 3D); point layers can be one primitive type among many.

### Conversion

- **COPC → MLT 3D:** For a given tile extent, read points from COPC (via octree/spatial query). Create one or more point primitives (`Topology.points`) with positions and, if desired, vertex attributes (e.g. color). Optionally add features for styling (e.g. classification).
- **MLT 3D → COPC:** Extract point primitives; write positions (and attributes) into LAS/LAZ and build COPC octree. Only point content is preserved; meshes and lines are out of scope for COPC.

---

## 6. Other Formats Used in Maps

### MVT (Mapbox Vector Tiles)

- **Relationship:** MLT 3D is designed to **coexist with MVT** in MLT. Same tile addressing (zoom/x/y); MVT for 2D vector layers, MLT 3D for 3D tile payloads. Feature properties and styling are conceptually aligned (feature_id, name–value properties).
- **Coordinate units:** Local tile coordinates use **MVT’s integer extent units** for X/Y (same tile grid space as 2D geometry, e.g. 0–4096 range semantics). **Z uses the same units** as X/Y so extrusions align with 2D.
- **Alignment:** The renderer must put MVT and 3D in the **same space**—typically scale 3D so horizontal extents match the MVT layer. If `extent` matches the MVT extent, **no scaling** is needed.

### KML / Collada (COLLADA)

- **KML:** Often used for 3D placemarks and simple geometry; not a tiled, multi-resolution format. MLT 3D is tile-based and more structured for rendering.
- **COLLADA:** Asset format; no tile or LOD model. Geometry could be converted to MLT 3D primitives per tile.

### glTF 2.0

- **Relationship:** MLT 3D **reuses glTF 2.0** conventions (matrices, endianness, angles, coordinate system, topology, index types). The fixed material model (base_color, ORM, normal_map, emissive) and PBR shading mode are aligned with glTF 2.0 metallic-roughness. Difference: MLT 3D is one-tile, flat scene, features for styling, per-primitive theme material lists for appearance switching; glTF is one asset, optional scene graph, no built-in "feature" or tile addressing.

---

## Conclusion

| Format | Best suited for | MLT 3D relationship |
|--------|------------------|----------------------|
| **3D Tiles** | Global 3D streaming, multi-format tileset | Same tile-based ideas; MLT 3D is one-tile, MVT-aligned, no intra-tile LOD; content can be converted. |
| **I3S** | Esri scene layers, node-tree LOD | Different structure; MLT 3D is flat and tile-scoped; conversion via flattening. |
| **3DPS** | Service API for 3D delivery | MLT 3D can be a payload format for a 3DPS service. |
| **CityGML/CityJSON** | 3D city semantics and geometry | MLT 3D can be a tiled, renderable output; conversion from city models is practical. |
| **COPC** | Point clouds, cloud-friendly access | MLT 3D can represent points in a tile; COPC can be a source for point tiles. |
| **glTF 2.0** | Single 3D asset, PBR | MLT 3D aligns with glTF 2.0 for geometry and material conventions; adds tile addressing, features, and per-primitive theme material lists. |

The MLT 3D schema is **simpler** than 3D Tiles (no tileset tree, one payload type) and **more map-oriented** than glTF (tile, features, styling). It fits a stack where 3D tiles are served like MVT (zoom/x/y) and consumed by a map renderer (e.g. MapLibre) with optional PBR and feature-based styling.
