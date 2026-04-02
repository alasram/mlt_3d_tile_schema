# Comparison: MLT 3D Tile Schema with Other 3D Geospatial Formats

This document compares the **MLT 3D tile schema** (draft), as defined in `format_3d_schema.zig`, with other formats commonly used for 3D geospatial content. The MLT 3D schema is designed for use with MapLibre Tile (MLT), alongside MVT, to support 2D+3D tile-based rendering in maps.

## Scope and intended use

The MLT 3D schema is a **geometry-only, style-driven format** for single tile payloads (one per zoom/x/y), designed to work within the **OSM and MapLibre ecosystem** and other ecosystems that want to expand MVT to 3D.

**Good fit:**
- Navigation and map visualization with 3D geometry (buildings, roads, terrain, trees) — similar in scope to [Google Maps Immersive Navigation](https://blog.google/products-and-products/products/maps/ask-maps-immersive-navigation/).
- Any MVT-based pipeline that needs to add 3D layers: the same style sheet model, feature properties, and tile addressing extend naturally to 3D.
- Ecosystems where the style sheet controls all appearance — producers encode geometry and data; renderers apply visual rules from the style sheet.

**Not a good fit:**
- Photorealistic 3D content with complex materials and textures (e.g. [Google Photorealistic 3D Tiles](https://developers.google.com/maps/documentation/tile/3d-tiles)) — use **Cesium 3D Tiles** or **glTF** for these use cases.
- Massive point cloud datasets requiring spatial subsetting — use **COPC** or **3D Tiles** with pnts.
- Rich semantic city models with thematic modules — use **CityGML/CityJSON**.
- Global-scale, multi-resolution 3D streaming with view-dependent refinement — use **3D Tiles** or **I3S**.

The key design principle: **any user familiar with MVT can easily use 3D data and author a style sheet for it.** A style sheet like [MapLibre Style Spec](https://maplibre.org/maplibre-style-spec/) will mainly work with the new data given its proximity to MVT.

**Important:** The schema is limited to **one tile** (one payload per zoom/x/y), the same as MVT. When comparing to formats that support a hierarchical structure (e.g. 3D Tiles, I3S), note that the tile hierarchy (zoom levels, spatial subdivision, LOD refinement) is **outside** this schema — it is defined by how the client requests tiles by zoom/x/y.

---

## Summary Table

| Aspect | MLT 3D (this schema) | 3D Tiles (Cesium) | I3S (Esri/OGC) | CityGML / CityJSON | COPC | glTF 2.0 |
|--------|----------------------|-------------------|----------------|---------------------|------|----------|
| **Primary focus** | Single-tile 3D geometry for map stacks | Streaming 3D geospatial tiles | Scene layers (buildings, mesh, point clouds) | 3D city model semantics | Point clouds only | Single 3D asset |
| **Appearance** | Style-sheet-driven (no materials in tile) | glTF materials, PBR | Per-layer / per-node materials | Appearance module | Point color/intensity | Full PBR materials |
| **Tile structure** | One tile per zoom/x/y (MVT-aligned) | Tileset tree, spatial hierarchy | Node tree, LOD | N/A (full dataset) | Single file, octree | N/A (single asset) |
| **Geometry** | Primitives + vertex buffers | glTF, b3dm, i3dm, pnts | Mesh/point per node | Boundary representation | LAS/LAZ points | Meshes, accessors |
| **Features / styling** | MVT-aligned feature properties | Batch table, feature IDs | Per-feature attributes | CityGML semantics | LAS point attributes | N/A |
| **Custom data** | Custom vertex attributes (i32/f32) | Metadata, extensions | Attribute fields | Thematic attributes | Extra bytes | Extensions |
| **Shared assets** | Asset Library (external MLT file) | External tilesets | Shared resources | N/A | N/A | N/A |

---

## 1. 3D Tiles (Cesium / OGC)

**Role:** Streaming massive 3D geospatial datasets with a tile tree, multiple tile formats, and refinement by geometric error.

### Comparison

- **Tile model**
  - **3D Tiles:** A *tileset* defines a tree of tiles. Each tile has a bounding volume, geometric error, and content (glTF, b3dm, i3dm, pnts). Tiles load based on view and refinement. The tile hierarchy is part of the format.
  - **MLT 3D:** A *single tile* is one payload (like one MVT tile). No tile hierarchy in the schema; zoom-level tiling handles LOD externally.

- **Appearance**
  - **3D Tiles:** Full glTF materials (PBR, textures, shading) embedded in tile content.
  - **MLT 3D:** No materials or textures in the tile. The style sheet controls all visual appearance. This keeps tiles small and gives the style sheet full control.

- **Features**
  - **3D Tiles:** Batch table (or metadata) with feature IDs.
  - **MLT 3D:** MVT-aligned `features` array with name-value properties and `feature_id` on instances.

- **When to use which**
  - **3D Tiles:** Photorealistic content, global-scale streaming, complex materials, view-dependent refinement.
  - **MLT 3D:** MVT-style map stacks where the style sheet drives appearance, navigation-grade 3D, OSM/MapLibre pipelines.

### Conversion

- **3D Tiles → MLT 3D:** Per tile, extract geometry from content (glTF/b3dm). Discard materials (style sheet takes over). Map batch table to `features`. Flatten scene into objects and instances.
- **MLT 3D → 3D Tiles:** Each MLT 3D tile becomes one 3D Tiles tile with glTF content. Materials would need to be generated from style sheet rules or defaults.

---

## 2. I3S (Indexed 3D Scene Layers, Esri / OGC)

**Role:** Scene layers for 3D GIS: buildings, 3D objects, integrated meshes, point clouds. Tree of nodes with geometry and attributes.

### Comparison

- **Structure**
  - **I3S:** Node tree; each node has geometry, textures, and attributes. Layer type determines schema. SLPK for file-based distribution.
  - **MLT 3D:** Flat scene list of object instances; no node tree. Zoom-level tiling handles LOD externally.

- **Geometry and appearance**
  - **I3S:** Layer-type-specific geometry with materials and textures per node.
  - **MLT 3D:** Fixed vertex types (i32 positions, optional banking angles, custom attributes). No materials — style sheet controls appearance.

- **When to use which**
  - **I3S:** Esri/ArcGIS ecosystems, rich per-node materials and LOD.
  - **MLT 3D:** MapLibre/OSM ecosystems, style-driven appearance, MVT interop.

### Conversion

- **I3S → MLT 3D:** For each tile extent, select I3S nodes. Export geometry as primitives (discard materials). Map attributes to `features`.
- **MLT 3D → I3S:** Object instances become I3S nodes. Layer type and appearance would need to be chosen.

---

## 3. CityGML / CityJSON

**Role:** 3D city and landscape models with rich semantics (buildings, roads, vegetation). CityJSON is a JSON encoding of a CityGML subset.

### Comparison

- **Data model**
  - **CityGML/CityJSON:** Thematic modules (Building, Road, Vegetation), boundary representation, appearance, semantic attributes.
  - **MLT 3D:** Generic primitives and objects; no built-in city semantics. Semantic meaning is carried in feature properties for style sheet filtering.

- **Geometry**
  - **CityGML/CityJSON:** Surfaces and solids (boundary rep); coordinates in a CRS; often one large dataset.
  - **MLT 3D:** Triangle/line/point primitives in local tile coordinates; one tile per zoom/x/y.

- **When to use which**
  - **CityGML/CityJSON:** Authoritative city models, thematic analysis, regulatory use cases.
  - **MLT 3D:** Tile-based map rendering of city geometry, where the style sheet interprets semantics via feature properties.

### Conversion

- **CityGML/CityJSON → MLT 3D:** Select city objects per tile. Tessellate surfaces into triangles. Export attributes as `features`. Transform coordinates to tile space.
- **MLT 3D → CityGML/CityJSON:** Possible but lossy — semantics must be inferred from feature properties.

---

## 4. Cloud Optimized Point Clouds (COPC)

**Role:** Single-file, cloud-friendly point cloud format (LAS/LAZ with internal octree).

### Comparison

- **Content type**
  - **COPC:** Point clouds only. Octree inside one file; range-readable for spatial queries.
  - **MLT 3D:** Meshes, lines, and points. Points are one topology type among several; not specialized for large point clouds.

- **When to use which**
  - **COPC:** Large lidar/point cloud datasets, cloud storage, spatial subsetting.
  - **MLT 3D:** Mixed 2D/3D map tiles where points are one layer alongside buildings and roads.

### Conversion

- **COPC → MLT 3D:** Read points for a tile extent. Create point primitives with positions and custom attributes (e.g. classification, intensity).
- **MLT 3D → COPC:** Extract point primitives; write to LAS/LAZ with COPC octree. Only point content transfers.

---

## 5. Other Formats

### MVT (Mapbox Vector Tiles)

- **Relationship:** MLT 3D is designed to **coexist with MVT** in MLT. Same tile addressing (zoom/x/y). MVT for 2D vector layers, MLT 3D for 3D geometry. Feature properties and the style sheet model are conceptually aligned.
- **Coordinate alignment:** Local tile coordinates use MVT's integer extent units for X/Y. Z uses the same units; `z_scale` converts to meters.
- **Style sheet:** A single style sheet targets both 2D MVT layers and 3D objects by name. The style sheet sees one combined MLT — it does not distinguish between frames.

### glTF 2.0

- **Relationship:** MLT 3D borrows glTF's topology model (triangles, triangle_strip, lines, points) but diverges significantly: MLT 3D carries **no materials** (style-sheet-driven), uses **integer vertex types** (i32 positions), and adds **feature properties** and **Asset Library** imports. glTF is a complete asset format with PBR materials, scene graphs, and animations — suited for photorealistic content that MLT 3D intentionally does not address.

### KML / COLLADA

- **KML:** Often used for 3D placemarks and simple geometry; not a tiled format. MLT 3D is tile-based and more structured for rendering.
- **COLLADA:** Asset format; no tile or LOD model. Geometry could be converted to MLT 3D primitives per tile.

---

## Conclusion

| Format | Best suited for | MLT 3D relationship |
|--------|-----------------|---------------------|
| **3D Tiles** | Global 3D streaming, photorealistic content, multi-format tilesets | MLT 3D is simpler (one-tile, no materials, style-driven); use 3D Tiles when materials/textures/refinement are needed. |
| **I3S** | Esri scene layers, node-tree LOD | Different ecosystem; MLT 3D is flat, tile-scoped, and style-driven. |
| **CityGML/CityJSON** | Semantic 3D city models | MLT 3D can be a tiled, renderable output from city models; semantics map to feature properties. |
| **COPC** | Large point clouds, cloud access | MLT 3D can represent points in a tile; COPC serves as a source for point tile generation. |
| **glTF 2.0** | Single 3D asset, PBR materials | MLT 3D borrows topology conventions but is tile-based, geometry-only, and style-driven. |

The MLT 3D schema is **simpler** than 3D Tiles (no tileset tree, no materials, one payload type) and **more map-oriented** than glTF (tile addressing, features, style-driven appearance). It fits a stack where 3D tiles are served like MVT (zoom/x/y) and consumed by a map renderer (e.g. MapLibre) with the style sheet controlling all visual presentation. For navigation-grade 3D content within the OSM and MapLibre ecosystem, it provides the right level of complexity without the overhead of formats designed for photorealistic or scientific use cases.
