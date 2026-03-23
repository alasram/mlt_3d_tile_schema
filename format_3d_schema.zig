//! 3D tile schema (draft)
//!
//! This file defines the schema types for a simple, renderer-friendly 3D tile format
//! designed to be used alongside MVT (Mapbox Vector Tiles) in MLT (MapLibre Tile format).
//!
//! ## Goals
//!
//! - Simple and MVT-aligned: one tile payload per zoom/x/y, flat scene, feature properties
//!   for styling — the same mental model as MVT.
//! - Fixed vertex attribute types: no generic attribute descriptors. Positions, UVs, normals,
//!   tangents, and colors have fixed types matching a strict subset of glTF 2.0.
//! - Fixed material model: a minimal PBR material (base color, ORM, normal map, emissive)
//!   with an optional simpler Lambertian shading mode.
//! - Data is stored as-is. There is no delta encoding. Binary compression is handled by the
//!   MLT encoding layer.
//!
//! ## Coordinate system
//!
//! The tile-local coordinate system is **left-handed with Z-up**:
//! - X points right (East).
//! - Y points down (South), matching MVT screen-space Y.
//! - Z points up; positive Z is above the map surface.
//!
//! The tile origin is at the top-left corner of the tile at ground level (Z = 0), consistent
//! with MVT geometry coordinates. Integer positions use the same extent unit as MVT for X and Y.
//! Z uses the same extent unit; `z_scale` on `MLT3DScene` converts Z to meters.
//!
//! ## Structure
//!
//! A `MLT3DScene` contains:
//! - `extent`: single integer defining the coordinate range (like MVT extent).
//! - `z_scale`: scale factor converting integer Z values to meters.
//! - `materials`: global pool of materials referenced by ID.
//! - `primitives`: geometry units (topology + vertex buffer + default material).
//! - `objects`: named collections of primitive IDs placed in tile space via `ObjectInstance`.
//! - `features`: per-object properties for styling (filters, colors, labels).
//! - `scene`: flat list of `ObjectInstance` values.
//!
//! ## Themes
//!
//! Each `Primitive3D` declares a default `material_id` and an optional list of
//! `theme_material_ids`. A style sheet selects which material is active for each primitive;
//! any material ID in `theme_material_ids` (or the default `material_id`) may be chosen.
//! This allows scene-wide appearance switching (e.g. day/night) without duplicating geometry.
//!
//! A style sheet may select a theme material by ID directly, or by matching `Material.name`
//! (e.g. requesting theme "night" activates the material whose `name` equals "night", provided
//! that material's ID is present in `theme_material_ids`). This is analogous to how MVT style
//! sheets select features by property name and value.
//!
//! ## Vertex attributes
//!
//! Every `VertexBuffer` has a fixed attribute set (all stored as raw bytes, no delta encoding):
//! - **Positions** (required): `vec3i32` — 3D signed 32-bit integer coordinates.
//! - **UV** (optional): `vec2u16` — texture coordinates; 0 = 0.0, 65535 = 1.0.
//! - **Normal** (optional): `vec3f32` — MUST be unit length (normalized by the producer).
//!   For line topology, providing normals enables tube extrusion; without normals (or tangents)
//!   the renderer may draw the line as a stroke or compute an arbitrary extrusion normal.
//! - **Tangent** (optional): `vec4f32` — xyz = tangent (MUST be unit length), w = bitangent sign.
//! - **Color** (optional): `vec4u8` — RGBA; values divided by 255 in shading formulas.
//!
//! ## Shading
//!
//! Each material declares a `ShadingModel`:
//! - **Flat**: `Final_Emissive + Final_Base_Color`. No lighting. Useful for icons and sprites.
//! - **Lambertian**: `Final_Emissive + Final_Base_Color * (ambient + clamp(dot(N, L), 0, 1))`.
//!   L and ambient are client-defined (not stored in the tile).
//! - **PBR**: follows glTF 2.0 metallic-roughness model.

// ----------------------------------------------------------------------------
// Topology
// ----------------------------------------------------------------------------

/// Draw topology for a primitive.
///
/// **Validation**: `primitive_restart` in `IndexBuffer` is only valid for `line_strip`
/// and `triangle_strip`.
///
/// Note: `triangle_fan` is intentionally absent — it is not supported in WebGPU and can
/// be trivially converted to a `triangles` list or `triangle_strip` before encoding.
pub const Topology = enum(u8) {
    points = 0,
    lines = 1,
    line_strip = 2,
    triangles = 3,
    triangle_strip = 4,
};

// ----------------------------------------------------------------------------
// Primitive types (positions, UVs, colors — kept as named structs for clarity)
// ----------------------------------------------------------------------------

/// 3D signed 32-bit integer vector. Used for vertex positions.
/// Values outside [0, extent) are valid; geometry may extend beyond tile bounds.
pub const Vec3i32 = struct { x: i32, y: i32, z: i32 };

/// 2D unsigned 16-bit vector. Used for UV coordinates.
/// 0 maps to 0.0, 65535 maps to 1.0.
/// For line topology, only U (x) is used; V (y) is ignored.
pub const Vec2u16 = struct { u: u16, v: u16 };

/// 3D 32-bit float vector. Used for normals, emissive factor, bounding volumes.
pub const Vec3f32 = struct { x: f32, y: f32, z: f32 };

/// 4D 32-bit float vector. Used for tangents, base color factor.
pub const Vec4f32 = struct { x: f32, y: f32, z: f32, w: f32 };

/// 4-component unsigned byte vector. Used for per-vertex colors.
/// Components are in [0, 255]; divided by 255.0 in shading formulas to produce [0.0, 1.0].
pub const Vec4u8 = struct { r: u8, g: u8, b: u8, a: u8 };

/// 4×4 column-major 32-bit float transformation matrix.
/// Column-major means the outer array index selects the column; there is no row-major transposition.
/// Storage: M[col][row] — the outer index is the column, the inner index is the row.
/// Applied as `p' = M * p` where `p = (x, y, z, 1)` is a column vector.
/// Translation is in the fourth column: M[3] = {tx, ty, tz, 1}.
/// When a transform field is null, the identity transform is assumed.
pub const Mat4x4f32 = [4][4]f32;

// ----------------------------------------------------------------------------
// IDs
// ----------------------------------------------------------------------------

/// Object identifier; unique within `MLT3DScene.objects`.
pub const ObjectId = u32;
/// Primitive identifier; unique within `MLT3DScene.primitives`.
pub const PrimitiveId = u32;
/// Material identifier; unique within `MLT3DScene.materials`.
pub const MaterialId = u32;
/// Feature identifier; unique within `MLT3DScene.features`.
pub const FeatureId = u32;

/// UTF-8 encoded string.
pub const Utf8String = []const u8;

// ----------------------------------------------------------------------------
// Bounding volumes
// ----------------------------------------------------------------------------

/// Axis-aligned bounding box in tile-local coordinates.
/// Uses `Vec3f32` (float) rather than `Vec3i32` because bounding volumes may represent
/// pre-transformed geometry (e.g. after applying a `Mat4x4f32` instance transform).
pub const BoundingBox = struct {
    /// Minimum corner (smallest X, Y, Z).
    min: Vec3f32,
    /// Maximum corner (largest X, Y, Z).
    max: Vec3f32,
};

/// Bounding sphere in tile-local coordinates.
pub const BoundingSphere = struct {
    center: Vec3f32,
    /// Radius in the same units as tile coordinates.
    radius: f32,
};

/// Optional bounding volume used for view-frustum culling.
/// When absent, consumers may compute bounds from geometry.
/// **Validation**: when present, the volume MUST be a conservative bound — it MUST fully
/// enclose all geometry in the associated coordinate space. Consumers are permitted to
/// skip rendering anything outside the reported volume.
pub const BoundingVolume = union(enum) {
    box: BoundingBox,
    sphere: BoundingSphere,
};

// ----------------------------------------------------------------------------
// Textures
// ----------------------------------------------------------------------------

/// Role of a texture in a material. Each kind has a fixed format and channel layout.
pub const TextureKind = enum(u8) {
    /// RGBA8. RGB channels are in sRGB color space. A channel is used for alpha/transparency.
    base_color,
    /// RGB8. Follows glTF 2.0 packing: R = Occlusion, G = Roughness, B = Metallic.
    orm,
    /// RGB8. Tangent-space normals. Coordinate conventions follow glTF 2.0.
    normal_map,
    /// RGB8. Emissive color in sRGB color space.
    emissive,
};

/// Texture content: either a URL string or an embedded binary blob.
/// Supported formats for blobs: JPEG, PNG, KTX2.
pub const TextureData = union(enum) {
    /// URL pointing to the texture resource. Any URL scheme is allowed (https://, http://, file://, etc.).
    url: Utf8String,
    /// Embedded binary blob (JPEG, PNG, or KTX2).
    blob: []const u8,
};

/// A single texture with a fixed role and data source.
pub const Texture = struct {
    kind: TextureKind,
    data: TextureData,
};

// ----------------------------------------------------------------------------
// Material
// ----------------------------------------------------------------------------

/// Alpha blending mode. Matches glTF 2.0 material.alphaMode.
pub const AlphaMode = enum(u8) {
    /// Alpha is ignored; the primitive is fully opaque.
    fully_opaque = 0,
    /// Fragments with alpha below `alpha_cutoff` are discarded; others are fully opaque.
    mask = 1,
    /// Standard alpha blending using the alpha channel.
    blend = 2,
};

/// Shading model for a material.
pub const ShadingModel = enum(u8) {
    /// Unlit shading: no lighting calculation.
    ///   output = Final_Emissive + Final_Base_Color
    /// Useful for icons, sprites, and overlays that should not be affected by scene lighting.
    flat,
    /// Simple diffuse shading:
    ///   output = Final_Emissive + Final_Base_Color * (ambient + clamp(dot(N, L), 0, 1))
    /// L (light direction) and ambient are client-defined; not stored in the tile.
    /// If doubleSided: N = FrontFacing ? N : -N.
    lambertian,
    /// Full glTF 2.0 PBR metallic-roughness model.
    /// If ORM texture is absent: Occlusion = 1.0, Roughness = roughness_factor, Metallic = metallic_factor.
    pbr,
};

/// Material used by one or more primitives.
///
/// **Final Base Color** (both shading models):
///   Multiply: normalized per-vertex color (vec4u8 / 255) × base_color_factor × sampled base_color_texture.
///   Each factor is optional; missing factors are treated as vec4(1, 1, 1, 1).
///
/// **Final Emissive** (both shading models):
///   If emissive_texture present: sample × emissive_factor.
///   If only emissive_factor: use directly.
///   If neither: vec3(0, 0, 0).
///
/// **Normal**: if normal_map_texture is absent, the geometric normal is used.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.materials`.
/// `alpha_cutoff` is only meaningful when `alpha_mode == mask`.
/// When a texture is present but the primitive's vertex buffer has no UVs, the texture is silently ignored.
/// UVs are allowed even when no texture is present; they are simply unused.
/// When a texture is present in a specific slot, its `Texture.kind` MUST match that slot:
/// - `base_color_texture.kind` MUST be `.base_color`
/// - `orm_texture.kind` MUST be `.orm`
/// - `normal_map_texture.kind` MUST be `.normal_map`
/// - `emissive_texture.kind` MUST be `.emissive`
/// Producer note: if any theme material for a primitive may use textures, include UVs in the vertex
/// buffer even when the default material is untextured — otherwise the textured theme will be silently
/// ignored at runtime.
pub const Material = struct {
    /// Unique within `MLT3DScene.materials`.
    id: MaterialId,
    /// Optional name used for theme selection. The client matches this against a requested theme name.
    name: ?Utf8String = null,

    shading_model: ShadingModel,

    // --- Textures (all optional) ---

    /// RGBA8 base color texture. RGB in sRGB; A = alpha.
    base_color_texture: ?Texture = null,
    /// RGB8 ORM texture: R = Occlusion, G = Roughness, B = Metallic (glTF 2.0 packing).
    orm_texture: ?Texture = null,
    /// RGB8 tangent-space normal map (glTF 2.0 conventions).
    normal_map_texture: ?Texture = null,
    /// RGB8 emissive texture in sRGB.
    emissive_texture: ?Texture = null,

    // --- Scalar factors ---

    /// Multiplied with base color texture sample and per-vertex color. Default: (1, 1, 1, 1).
    base_color_factor: Vec4f32 = .{ .x = 1, .y = 1, .z = 1, .w = 1 },
    /// Metallic factor. Default: 0.0.
    /// Note: glTF 2.0 defaults to 1.0, but 0.0 is a more practical default for map geometry
    /// (most surfaces are non-metallic). Producers targeting glTF interop should set this explicitly.
    metallic_factor: f32 = 0.0,
    /// Roughness factor. Default: 1.0.
    roughness_factor: f32 = 1.0,
    /// Emissive factor. Multiplied with emissive texture if present. Default: (0, 0, 0).
    emissive_factor: Vec3f32 = .{ .x = 0, .y = 0, .z = 0 },

    double_sided: bool = false,
    alpha_mode: AlphaMode = .fully_opaque,
    /// Cutoff threshold for `alpha_mode == mask`. Default: 0.5.
    alpha_cutoff: f32 = 0.5,
};

// ----------------------------------------------------------------------------
// Vertex buffer
// ----------------------------------------------------------------------------

/// Index buffer for indexed draw calls. Indices are always uint32, stored as-is.
///
/// Note: MLT encoding may apply compression. A client may inspect the maximum index value
/// to determine whether a smaller in-memory representation (e.g. 16-bit or 8-bit) is usable
/// after decompression.
///
/// **Validation**: `primitive_restart` MUST only be true when the containing primitive's
/// topology is `line_strip` or `triangle_strip`. The restart sentinel is 0xFFFFFFFF.
pub const IndexBuffer = struct {
    /// When true, 0xFFFFFFFF in the index stream ends the current strip and begins a new one.
    /// Only valid for `line_strip` and `triangle_strip` topologies.
    primitive_restart: bool = false,
    /// Number of index elements.
    element_count: u32,
    /// Raw bytes: element_count × 4 bytes (uint32, little-endian, stored as-is).
    data: []const u8,
};

/// Fixed vertex attribute set for a primitive. All buffers store data as-is (no delta encoding).
///
/// Buffer layouts (all little-endian):
/// - positions: vertex_count × 12 bytes (3 × i32)
/// - uvs:       vertex_count × 4 bytes  (2 × u16)
/// - normals:   vertex_count × 12 bytes (3 × f32)
/// - tangents:  vertex_count × 16 bytes (4 × f32)
/// - colors:    vertex_count × 4 bytes  (4 × u8)
///
/// **Validation**:
/// - All present attribute buffers MUST contain exactly `vertex_count` elements.
/// - For `line_strip` and `lines` topology, both `normals` and `tangents` are optional.
///   Without either, the renderer may draw the line as a stroke or compute an arbitrary extrusion
///   normal. With normals only, tube extrusion is possible. With both normals and tangents,
///   flat ribbon extrusion (e.g. road markings) is possible.
pub const VertexBuffer = struct {
    /// Optional index buffer. When absent, vertices are drawn in sequential order.
    indices: ?IndexBuffer = null,

    /// Number of vertices. All present attribute buffers must contain this many elements.
    vertex_count: u32,

    /// Positions: vec3i32. Required. Values outside [0, extent) are valid (outside tile bounds).
    positions: []const u8,

    /// UV coordinates: vec2u16. Optional. Valid for all topology types.
    /// For line topology, only U is used (distance along line); V is ignored.
    uvs: ?[]const u8 = null,

    /// Normals: vec3f32. Optional for all topology types.
    /// MUST be unit length. Producers MUST normalize before encoding.
    /// For line topology: represents the up direction for mesh extrusion (tube or ribbon).
    /// When absent for line topology, the renderer may compute an arbitrary extrusion normal.
    normals: ?[]const u8 = null,

    /// Tangents: vec4f32. Optional for all topology types.
    /// xyz MUST be unit length. Producers MUST normalize before encoding. w = bitangent sign (+1 or -1).
    /// For line topology: provides the along-line direction for mesh generation (e.g. road width).
    tangents: ?[]const u8 = null,

    /// Per-vertex RGBA colors: vec4u8. Optional.
    /// Component values in [0, 255] are divided by 255.0 in shading formulas.
    colors: ?[]const u8 = null,
};

// ----------------------------------------------------------------------------
// Primitives and objects
// ----------------------------------------------------------------------------

/// One drawable geometry unit: topology, vertex buffer, and materials.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.primitives`.
/// `material_id` when present MUST refer to an entry in `MLT3DScene.materials`.
/// Every entry in `theme_material_ids` MUST refer to an entry in `MLT3DScene.materials`.
pub const Primitive3D = struct {
    /// Unique within `MLT3DScene.primitives`.
    id: PrimitiveId,
    topology: Topology,
    /// Default material applied when the style sheet does not select an alternate.
    /// When null, the renderer uses a default base color of (255, 255, 255, 255), zero
    /// emissive (0, 0, 0), and `flat` shading (no lighting).
    material_id: ?MaterialId = null,
    /// Additional materials available for alternate themes (e.g. "night", "winter").
    /// A style sheet may select any material ID from this list instead of the default `material_id`,
    /// either by ID directly or by matching `Material.name` (e.g. requesting theme "night" activates
    /// the material whose `name` equals "night", provided its ID is in this list). This is analogous
    /// to how MVT style sheets select features by property name and value.
    /// Each entry MUST refer to an entry in `MLT3DScene.materials`.
    theme_material_ids: []const MaterialId = &[_]MaterialId{},
    /// Optional bounding volume in primitive-local space for culling.
    bounding_volume: ?BoundingVolume = null,
    vertex_buffer: VertexBuffer,
};

/// Named collection of primitives placed in tile space via `ObjectInstance`.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.objects`.
/// Every entry in `primitive_ids` MUST refer to an entry in `MLT3DScene.primitives`.
pub const Object3D = struct {
    /// Unique within `MLT3DScene.objects`.
    id: ObjectId,
    name: ?Utf8String = null,
    /// Optional bounding volume in object-local space for culling.
    bounding_volume: ?BoundingVolume = null,
    /// Primitives that make up this object, referenced by ID.
    primitive_ids: []const PrimitiveId,
};

// ----------------------------------------------------------------------------
// Scene
// ----------------------------------------------------------------------------

/// Placement of an object into tile space.
///
/// **Validation**: `object_id` MUST refer to an entry in `MLT3DScene.objects`.
/// When `feature_id` is present it MUST refer to an entry in `MLT3DScene.features`.
pub const ObjectInstance = struct {
    /// Must refer to an entry in `MLT3DScene.objects`.
    object_id: ObjectId,
    /// Transform from object space to tile space. When null, identity is assumed.
    object_to_tile: ?Mat4x4f32 = null,
    /// Optional bounding volume in tile space (pre-transformed, for efficient culling).
    bounding_volume: ?BoundingVolume = null,
    /// Optional link to per-feature metadata in `MLT3DScene.features`.
    feature_id: ?FeatureId = null,
};

// ----------------------------------------------------------------------------
// Features
// ----------------------------------------------------------------------------

/// Value of a single feature property. Used by styling tools for filtering, coloring, and labeling.
pub const FeaturePropertyValue = union(enum) {
    bool: bool,
    /// Signed integer value. i64 covers all practical styling use cases.
    int: i64,
    /// Floating point value.
    float: f64,
    /// UTF-8 string (e.g. name, category, identifier).
    string: Utf8String,
};

/// A named property belonging to a feature.
///
/// Note: property names within a feature are not required to be unique (following MVT conventions).
/// Consumers encountering duplicate names within one feature may use the last occurrence.
/// Feature identity is determined by `Feature.id`, not by name.
pub const FeatureProperty = struct {
    name: Utf8String,
    value: FeaturePropertyValue,
};

/// A feature: an ID and its associated properties.
/// Referenced by `ObjectInstance.feature_id`. Modeled after MVT feature properties.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.features`.
pub const Feature = struct {
    /// Unique within `MLT3DScene.features`.
    id: FeatureId,
    /// Named properties usable by styling tools (filters, colors, labels).
    properties: []const FeatureProperty,
};

// ----------------------------------------------------------------------------
// Tile
// ----------------------------------------------------------------------------

/// Top-level tile payload.
///
/// **Validation (normative)**. Producers MUST satisfy all of the following;
/// consumers/validators MUST reject tiles that do not:
/// - **ID uniqueness**: `Primitive3D.id` unique within `primitives`; `Object3D.id` within
///   `objects`; `Material.id` within `materials`; `Feature.id` within `features`.
///   `FeatureProperty.name` is NOT required to be unique within a feature (following MVT conventions).
/// - **Referential integrity**: Every `Object3D.primitive_ids` entry MUST refer to an existing
///   primitive. Every `ObjectInstance.object_id` MUST refer to an existing object.
///   `Primitive3D.material_id` when present MUST refer to an existing material.
///   Every entry in `Primitive3D.theme_material_ids` MUST refer to an existing material.
///   `ObjectInstance.feature_id` when present MUST refer to an existing feature.
/// - **UV / texture**: `uvs` and textures may be combined freely. When a texture is present but
///   the vertex buffer has no `uvs`, the texture is silently ignored. When `uvs` are present but
///   no texture is active, the UVs are unused.
/// - **Line topology attributes**: `normals` and `tangents` are both optional for `line_strip`
///   and `lines`. Without either, the renderer draws a stroke or computes its own extrusion
///   normal. With normals only, tube extrusion is possible. With normals and tangents, flat
///   ribbon extrusion (e.g. road markings) is possible.
/// - **Primitive restart**: `IndexBuffer.primitive_restart` MUST only be true for `line_strip`
///   and `triangle_strip` topologies.
pub const MLT3DScene = struct {
    /// Schema version. Producers MUST set this to 1. Consumers MUST reject tiles with an
    /// unrecognized version number.
    version: u32 = 1,

    /// Tile coordinate extent (single integer, like MVT).
    /// Defines the integer coordinate range for X and Y: [0, extent).
    /// Z uses the same unit. Coordinates outside this range are valid but lie outside the tile.
    extent: u32,

    /// Z scale factor (float32, meters per extent unit).
    /// height_in_meters = z_value * z_scale.
    z_scale: f32,

    /// Global material pool. Materials are defined once and referenced by ID from primitives.
    materials: []const Material,

    /// Geometry primitives. Each primitive declares a default material and optional
    /// alternate theme materials selectable by the style sheet.
    primitives: []const Primitive3D,

    /// Named collections of primitives. Placed into the scene via `ObjectInstance`.
    objects: []const Object3D,

    /// Per-object properties for styling (filters, colors, labels). Aligned with MVT feature model.
    features: []const Feature,

    /// Scene: flat list of object instances in tile space.
    scene: []const ObjectInstance,
};
