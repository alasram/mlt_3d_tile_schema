//! 3D tile schema (draft)
//!
//! This file defines schema types for a renderer-agnostic 3D tile data model.
//! It intentionally focuses on the logical schema (what the data means), while buffer payloads
//! are represented as raw bytes until a concrete binary encoding is specified.
//!
//! ## Geospatial anchoring
//!
//! This format does not define geospatial anchoring (e.g. coordinate reference system, origin,
//! or geographic bounds). Tile coordinates and placement follow the **same tile structure as MVT**:
//! tiles identified by zoom and x/y; 3D content uses **local tile coordinates** within that tile.
//!
//! **Coordinate units (MVT-aligned):** Local tile coordinates **match MVT’s integer extent units**
//! for the horizontal plane: MVT encodes 2D geometry as integers in a tile grid (e.g. a fixed extent
//! such as 0–4096 per axis). In this schema, **X and Y use that same integer-extent space**. **Z uses the
//! same unit system** as X and Y (one vertical extent in the same integer units), so 2D positions and
//! extrusions stay consistent when combined with MVT layers.
//!
//! **Combining with MVT:** The renderer or client **must place 2D MVT data and this 3D tile in the same
//! space**. Typically the 3D content is **scaled so that its horizontal extents match the MVT tile
//! extent** used for 2D geometry. If the 3D tile’s `TileExtents` (X/Y) **match** the MVT layer’s extent
//! (same range and units), **no scaling is required** to align; transforms and positions can be shared
//! directly. If extents differ, apply a uniform (or per-axis) scale so 3D positions line up with MVT.
//!
//! ## Structure
//!
//! A `Tile3D` has a scene: a flat list of `SceneItem` values.
//! A `SceneItem` is either an `ObjectInstance` or a `LodGroupInstance`.
//! An `ObjectInstance` places one object in the tile.
//! `LodGroupInstance` places an object with multiple levels of detail (the client picks a variant).
//! Each instance references an `Object3D` and has a transform into tile space.
//! The scene can contain multiple instances that reference the same `Object3D` (each with its own transform).
//! An `Object3D` is composed of `PrimitiveInstance` values; each references a `Primitive3D` and has an optional
//! transform into object space.
//! A `Primitive3D` contains a `VertexBuffer` and optionally references a `Material`.
//! A `Material` holds textures and attributes used when rendering the primitive.
//! A `VertexBuffer` has positions and a set of per-vertex attributes; it can have an optional index buffer.
//!
//! **glTF 2.0 (transform math conventions)**: Matrix storage and operations used by `Transform` **follow
//! glTF 2.0** conventions: matrices are column-major and applied to column vectors; translation is in the
//! fourth column. Encoded numeric data is **little-endian**. All angles (e.g. Euler) are in **radians**.
//!
//! **MVT (tile-local space)**: The final coordinate space of geometry in this format is **tile-local** and
//! **MVT-aligned** (see the coordinate-units section above). In other words: transforms are expressed using
//! glTF conventions, but the transformed positions live in the same local tile space used to align with
//! conventional 2D MVT content.
//!
//! ## Semantics and rendering
//!
//! The schema is **generic**: materials and vertex attributes are not tied to a fixed shading model.
//! Tiles may optionally provide **TileSemantics**, which assign well-known semantics (e.g. base color,
//! metallic, normal, tangent) to a subset of textures and attributes. When present, these allow a
//! renderer to interpret the tile as PBR and render it the **same way as any glTF 2.0 renderer**,
//! without project-specific names or style-driven mapping.
//!
//! The same vertex semantics (**tangent**, **normal**) can be used by a renderer to **turn a road
//! polyline into a mesh**: when a style specifies road width and thickness (e.g. line-width, extrusion),
//! the renderer can use the polyline geometry plus tangent (along the road) and normal (up) to
//! generate a 3D road mesh, analogous to how a style specifies road width for 2D MVT line rendering.
//!
//! **Features**: A tile may attach **optional features** to objects (via `feature_id` on object and LOD
//! instances). Each feature has a set of properties (name–value pairs). These properties can be used by
//! a **styling tool** to drive appearance, filtering, or labeling (e.g. by road type, building height,
//! or any custom attribute), in the same way MVT feature properties drive 2D styling.
//!
//! Conventions (precision, delta encoding, scale/normalization, euler order, optional transforms) and
//! normative validation requirements are documented on the relevant types below.

/// Primitive topology / draw mode. Values match glTF 2.0 primitive `mode` (GL enum: POINTS, LINES,
/// LINE_LOOP, LINE_STRIP, TRIANGLES, TRIANGLE_STRIP, TRIANGLE_FAN).
pub const Topology = enum(u8) {
    points = 0,
    lines = 1,
    line_loop = 2,
    line_strip = 3,
    triangles = 4,
    triangle_strip = 5,
    triangle_fan = 6,
};

/// Index scalar type for index buffers. Follows glTF 2.0 accessor component types for indices:
/// UNSIGNED_BYTE (5121), UNSIGNED_SHORT (5123), UNSIGNED_INT (5125).
pub const IndexType = enum(u8) {
    u8,
    u16,
    u32,
};

/// Scalar element type used by attribute and position type tags.
///
/// **Validation**: `ScalarType.bool` **MUST** only be used with `AttributeShape.scalar`.
/// For `bool`, `normalization` **MUST** be `none` and `encoding` **MUST** be `none`.
pub const ScalarType = enum(u8) {
    i8,
    i16,
    i32,
    i64,
    u8,
    u16,
    u32,
    u64,
    f16,
    f32,
    f64,
    bool, // Stored as an 8-bit value.
};

/// Shape of a generic attribute element.
pub const AttributeShape = enum(u8) {
    scalar,
    vec2,
    vec3,
    vec4,
};

/// Integer normalization mode for attributes/positions.
/// Optional interpretation: integer values are mapped to `[-1, 1]` (signed) or `[0, 1]` (unsigned).
pub const Normalization = enum(u8) {
    /// No normalization. Integer values are interpreted as integers.
    none,
    /// Unsigned normalized: maps the integer range to [0, 1].
    normalized_unsigned,
    /// Signed normalized: maps the integer range to [-1, 1].
    normalized_signed,
};

/// AttributeValueType represents an attribute value of a vertex
pub const AttributeValueType = struct {
    /// Value shape + scalar element type.
    ///
    /// Notes:
    /// - `normalization` affects how integer values are interpreted (e.g. normals, colors).
    /// - Delta encoding rules are defined by the buffer that carries this type tag.
    /// Shape of the value (scalar/vec2/vec3/vec4).
    shape: AttributeShape,
    /// Scalar element type.
    scalar: ScalarType,
    /// Optional integer normalization mode.
    normalization: Normalization = .none,
};

/// Shape of a position element.
pub const PositionShape = enum(u8) {
    vec2,
    vec3,
};

/// PositionValueType represents a position value of a vertex
pub const PositionValueType = struct {
    /// 2D or 3D position.
    shape: PositionShape,
    /// Scalar element type for each component.
    scalar: ScalarType,
    /// Optional integer normalization mode.
    normalization: Normalization = .none,
};

/// Delta encoding mode for integer buffers.
///
/// **Convention**: Buffers may store values as-is (`none`) or as deltas relative to the first element (`from_first`).
/// Applicable to indices, vertices, and attributes.
///
/// **Validation**: `from_first` is only valid for integer scalar/vector element types.
/// For floating point types (`f16`, `f32`, `f64`) and for `bool`, `encoding` **MUST** be `none`.
/// For vector shapes (`vec2`, `vec3`, `vec4`), deltas apply component-wise.
pub const DeltaEncoding = enum(u8) {
    /// Values stored as-is.
    none,
    /// Each element is stored as a delta from the first element; decode as `value[i] = value[0] + delta[i]`.
    /// For vector shapes (vec2/vec3/vec4), deltas are applied component-wise.
    /// Delta encoding only applies to integer scalar and integer vector types.
    /// For floating point scalar/vector types, encoding must be `none`.
    from_first,
};

/// Ordering rule when both normalization and scaling apply.
pub const ScaleOrder = enum(u8) {
    /// Apply scale before normalization.
    scale_before_normalization,
    /// Apply scale after normalization.
    scale_after_normalization,
};

/// Float values used in the schema where multiple precisions are allowed.
/// **Convention**: Vectors, matrices, quaternions, euler angles, poses, and transforms support
/// f16, f32, or f64. Use lower precision for smaller payloads.
pub const Float = union(enum) {
    f16: f16,
    f32: f32,
    f64: f64,
};

/// Scale factor for decoding integer vertex or attribute data to float.
/// When present: `value_float = value_int * factor`.
///
/// **Convention**: When both normalization and scaling apply (i.e. for normalized integer attributes),
/// `order` determines whether scaling happens before or after normalization.
/// Intended for normals, tangents, colors, UVs, and (optionally) positions.
pub const Scale = struct {
    /// Scale factor used when decoding integer vertex/attribute data into float.
    /// Decode as `value_float = value_int * factor`.
    factor: Float,
    /// When both normalization and scaling apply (normalized integer attributes),
    /// determines whether scaling happens before or after normalization.
    order: ScaleOrder,
};

/// Extents of the tile along each axis. Values are in **MVT-aligned integer extent units**:
/// the same scaling as MVT tile grid coordinates for 2D (X, Y). **Z is in the same units** as X and Y
/// (vertical extent in that space). Typical use: match the MVT layer extent (e.g. 4096 × 4096 for X/Y);
/// if 2D extents match between MVT and this tile, no scaling is needed to align layers.
pub const TileExtents = struct {
    /// Tile extent along X (MVT-aligned integer extent units, same as MVT horizontal grid range).
    x: u32,
    /// Tile extent along Y (MVT-aligned integer extent units, same as MVT horizontal grid range).
    y: u32,
    /// Tile extent along Z (same units as X/Y; vertical range in the same integer space as 2D extrusion).
    z: u32,
};

// --- Bounding volumes (for culling and LOD) ---

/// Axis-aligned bounding box in tile-local coordinates (MVT-aligned integer extent units; same as
/// positions and `TileExtents`).
/// Min and max corners use the same units as tile coordinates.
pub const BoundingBox = struct {
    /// Minimum corner (smallest X, Y, Z).
    min: Vec3f32,
    /// Maximum corner (largest X, Y, Z).
    max: Vec3f32,
};

/// Bounding sphere in tile-local coordinates.
pub const BoundingSphere = struct {
    /// Center of the sphere.
    center: Vec3f32,
    /// Radius (same units as tile coordinates).
    radius: f32,
};

/// Optional bounding volume for an object or primitive.
/// Used for view-frustum culling and LOD selection. When absent, consumers may compute bounds from geometry.
pub const BoundingVolume = union(enum) {
    /// Axis-aligned box (min and max corners).
    box: BoundingBox,
    /// Sphere (center + radius).
    sphere: BoundingSphere,
};

/// UTF-8 encoded string.
pub const Utf8String = []const u8;

/// Object identifier (unique within `Tile3D.objects`).
pub const ObjectId = u32;
/// Primitive identifier (unique within `Tile3D.primitives`).
pub const PrimitiveId = u32;
/// Material identifier (unique within `Tile3D.materials`).
pub const MaterialId = u32;
/// Material attribute identifier (unique within a material).
pub const MaterialAttributeId = u32;
/// Texture identifier (unique within a material).
pub const TextureId = u32;
/// Vertex attribute identifier (unique within a primitive's vertex attribute list).
pub const VertexAttributeId = u32;
/// Feature identifier. Scene items reference features via `feature_id`
pub const FeatureId = u32;

/// Type tag for a decoded texel value.
pub const TextureFormat = struct {
    /// Example: `.shape = .vec4, .scalar = .u8, .colorspace = .srgb`.
    /// Number of scalar components per texel.
    shape: AttributeShape,
    /// Scalar element type per component.
    scalar: ScalarType,
    /// Optional color space / transfer function.
    colorspace: ?ColorSpace = null,
};

/// Color space / transfer function used to interpret decoded texture values.
pub const ColorSpace = enum(u8) {
    /// Linear transfer function.
    linear,
    /// sRGB transfer function.
    srgb,
};

pub const Texture = struct {
    /// **Validation**: Must be unique within the containing material's `textures` list.
    id: TextureId,
    /// Texture location.
    ///
    /// Requirements (draft): must start with `file://` or `https://`.
    path: Utf8String,
    format: TextureFormat,
};

/// Scalar literal used in `MaterialAttributeValue`.
pub const ScalarValue = union(enum) {
    i8: i8,
    i16: i16,
    i32: i32,
    i64: i64,
    u8: u8,
    u16: u16,
    u32: u32,
    u64: u64,
    f16: f16,
    f32: f32,
    f64: f64,
    bool: bool,
};

/// Material attribute value (scalar or small vector of scalars).
pub const MaterialAttributeValue = union(enum) {
    /// Single scalar.
    scalar: ScalarValue,
    /// Two-element vector.
    vec2: [2]ScalarValue,
    /// Three-element vector.
    vec3: [3]ScalarValue,
    /// Four-element vector.
    vec4: [4]ScalarValue,
};

/// Named material attribute (generic metadata used by styling/shading systems).
/// **Validation**: `id` must be unique within the containing material's `attributes` list.
pub const MaterialAttribute = struct {
    /// Attribute ID must be unique within the containing material's attribute list.
    id: MaterialAttributeId,
    /// Optional human-readable name.
    name: ?Utf8String = null,
    /// Attribute value.
    value: MaterialAttributeValue,
};

/// **Validation**: `id` must be unique within `Tile3D.materials`.
/// Texture and attribute IDs are scoped to this material; `TileSemantics` bindings must reference IDs that exist here.
pub const Material = struct {
    /// Must be unique within `Tile3D.materials`.
    id: MaterialId,
    name: ?Utf8String = null,
    /// Textures are scoped to this material (texture IDs are not global).
    textures: []const Texture,
    /// Generic attributes used by styling/shading systems. IDs are scoped to this material.
    /// See `TileSemantics` for optional well-known semantics without project-specific names.
    attributes: []const MaterialAttribute,
    /// When using alpha cutout (material attribute semantic `alpha_mode` == `AlphaMode.mask`), a scalar
/// attribute with semantic `alpha_cutoff` or this threshold defines the cutoff value.
    alpha_cutoff_threshold: ?Float = null,
};

// --- Vectors, matrices, orientations: f16 / f32 / f64 (lowercase = Zig scalar convention) ---

/// 2D vector (f16).
pub const Vec2f16 = struct { x: f16, y: f16 };
/// 2D vector (f32).
pub const Vec2f32 = struct { x: f32, y: f32 };
/// 2D vector (f64).
pub const Vec2f64 = struct { x: f64, y: f64 };

/// 3D vector (f16).
pub const Vec3f16 = struct { x: f16, y: f16, z: f16 };
/// 3D vector (f32).
pub const Vec3f32 = struct { x: f32, y: f32, z: f32 };
/// 3D vector (f64).
pub const Vec3f64 = struct { x: f64, y: f64, z: f64 };

/// 4D vector (f16).
pub const Vec4f16 = struct { x: f16, y: f16, z: f16, w: f16 };
/// 4D vector (f32).
pub const Vec4f32 = struct { x: f32, y: f32, z: f32, w: f32 };
/// 4D vector (f64).
pub const Vec4f64 = struct { x: f64, y: f64, z: f64, w: f64 };

/// Euler order: roll (X), pitch (Y), yaw (Z).
/// **Convention**: angles represent **intrinsic** rotations about the local axes in X then Y then Z.
/// All angles are in **radians** (glTF 2.0).
pub const Eulerf16 = struct { roll: f16, pitch: f16, yaw: f16 };
/// Euler angles in f32.
pub const Eulerf32 = struct { roll: f32, pitch: f32, yaw: f32 };
/// Euler angles in f64.
pub const Eulerf64 = struct { roll: f64, pitch: f64, yaw: f64 };

/// Quaternion orientation (f16).
/// **Validation**: Quaternions **SHOULD** be normalized (unit length). Consumers **MAY** normalize non-unit
/// quaternions during decoding.
pub const Quatf16 = struct { x: f16, y: f16, z: f16, w: f16 };
/// Quaternion orientation (f32).
pub const Quatf32 = struct { x: f32, y: f32, z: f32, w: f32 };
/// Quaternion orientation (f64).
pub const Quatf64 = struct { x: f64, y: f64, z: f64, w: f64 };

/// 4×4 transformation matrix. Indexing is [row][column]. Storage and operations follow glTF 2.0
/// (column-major storage, column vectors, translation in fourth column).
pub const Mat4x4f16 = [4][4]f16;
/// 4×4 transformation matrix (f32).
pub const Mat4x4f32 = [4][4]f32;
/// 4×4 transformation matrix (f64).
pub const Mat4x4f64 = [4][4]f64;

/// Orientation encoded as Euler angles or quaternion (f16).
pub const OrientationF16 = union(enum) {
    euler: Eulerf16,
    quaternion: Quatf16,
};
/// Orientation encoded as Euler angles or quaternion (f32).
pub const OrientationF32 = union(enum) {
    euler: Eulerf32,
    quaternion: Quatf32,
};
/// Orientation encoded as Euler angles or quaternion (f64).
pub const OrientationF64 = union(enum) {
    euler: Eulerf64,
    quaternion: Quatf64,
};

/// Pose (location + orientation) in f16.
pub const PoseF16 = struct {
    /// Translation component.
    location: Vec3f16,
    /// Orientation component.
    orientation: OrientationF16,
};
/// Pose (location + orientation) in f32.
pub const PoseF32 = struct {
    /// Translation component.
    location: Vec3f32,
    /// Orientation component.
    orientation: OrientationF32,
};
/// Pose (location + orientation) in f64.
pub const PoseF64 = struct {
    /// Translation component.
    location: Vec3f64,
    /// Orientation component.
    orientation: OrientationF64,
};

/// Transform in any supported float precision (f16, f32, f64).
///
/// **Convention**: When a transform field is `null` (e.g. in `PrimitiveInstance.primitive_to_object`),
/// it is interpreted as the identity transform.
///
/// Matrix conventions (glTF 2.0): matrices are indexed as `[row][column]`; storage is column-major;
/// matrices are applied to column vectors `p' = M * p` with `p = (x, y, z, 1)`; translation in the
/// fourth column `M[0][3]`, `M[1][3]`, `M[2][3]`. The resulting positions are interpreted in the
/// tile-local coordinate space described in the module docs (MVT-aligned extent units).
pub const Transform = union(enum) {
    /// 4×4 matrix transform in f16 precision.
    matrix_f16: Mat4x4f16,
    /// Pose (location + orientation) in f16 precision.
    pose_f16: PoseF16,
    /// 4×4 matrix transform in f32 precision.
    matrix_f32: Mat4x4f32,
    /// Pose (location + orientation) in f32 precision.
    pose_f32: PoseF32,
    /// 4×4 matrix transform in f64 precision.
    matrix_f64: Mat4x4f64,
    /// Pose (location + orientation) in f64 precision.
    pose_f64: PoseF64,
};

/// Index buffer: type of each index, optional delta encoding, and raw bytes.
/// Delta encoding (`from_first`) applies per element: each stored value is a delta
/// from the first element.
/// Delta encoding only applies to integer index scalar types.
///
/// **Validation**: If `primitive_restart = true`, the containing `Primitive3D.topology` **MUST** be
/// `line_strip` or `triangle_strip`. The restart index is the largest integer representable by `index_type`.
/// When `encoding = from_first`, the restart index is represented as that value in the encoded stream.
///
/// Stride: when `element_stride` is null the buffer is tightly packed; otherwise it is the bytes from one
/// element to the next.
/// **Validation**: `element_count` **MUST** be present. When `element_stride != null`, it **MUST** be >=
/// element byte size.
/// `data.len` **MUST** be consistent with element count and stride for the chosen encoding.
pub const IndexBuffer = struct {
    /// Scalar type of each index.
    index_type: IndexType,
    /// Optional delta encoding applied to the index stream.
    encoding: DeltaEncoding,
    /// Optional strip restart support (only meaningful for strip topologies).
    /// When true, the restart index is the largest integer representable by `index_type`.
    primitive_restart: bool = false,
    /// Optional byte stride between consecutive elements.
    element_stride: ?u32 = null,
    /// Number of decoded index elements.
    element_count: u32,
    /// Raw encoded payload bytes.
    data: []const u8,
};

/// Position buffer: type, optional delta encoding, optional scale, and raw bytes.
/// When scale is present, position_float = position_int * scale.factor.
/// When `position_type.normalization` is set for integer positions, integer values are interpreted as normalized
/// ranges (`[-1, 1]` or `[0, 1]`) before or after scaling depending on `Scale.order`.
/// Delta encoding only applies to integer position types; for floating point, encoding must be `none`.
///
/// **Validation**: `element_count` **MUST** be present. When `element_stride != null`, it **MUST** be >=
/// element byte size.
/// `data.len` **MUST** be consistent with element count and stride for the chosen encoding.
pub const PositionsBuffer = struct {
    /// Type tag for each position element.
    position_type: PositionValueType,
    /// Optional delta encoding. Must be `none` for floating point element types.
    encoding: DeltaEncoding,
    /// Optional integer→float scale factor (commonly used for compact i16 positions).
    scale: ?Scale = null,
    /// Optional byte stride between consecutive elements.
    element_stride: ?u32 = null,
    /// Number of decoded position elements.
    element_count: u32,
    /// Raw encoded payload bytes.
    data: []const u8,
};

/// Per-vertex attribute (e.g. normal, color, uv): type, encoding, optional scale, data.
/// The attribute `id` always exists; `name` is optional. See `TileSemantics` for optional well-known semantics.
/// Delta encoding only applies to integer attribute types; for floating point and bool, encoding must be `none`.
///
/// **Validation**: `id` must be unique within the primitive's `vertex_buffer.attributes`.
/// `element_count` **MUST** equal `vertex_buffer.positions.element_count`. When `element_stride != null`,
/// it **MUST** be >= element byte size.
/// `data.len` **MUST** be consistent with element count and stride for the chosen encoding.
pub const VertexAttribute = struct {
    /// Attribute ID must be unique within the containing primitive's attribute list.
    id: VertexAttributeId,
    name: ?Utf8String = null,
    /// Type tag for the attribute stream.
    value_type: AttributeValueType,
    /// Optional delta encoding. Must be `none` for floating point and bool element types.
    encoding: DeltaEncoding,
    /// Optional integer→float scale factor.
    scale: ?Scale = null,
    element_stride: ?u32 = null,
    element_count: u32,
    data: []const u8,
};

/// Per-channel meaning of a texture (for default shading). Each texture channel (R,G,B,A) can be
/// assigned an independent semantic, allowing arbitrary packing (e.g. RGB = base color, or R = metallic,
/// G = roughness in one texture). Use the _r/_g/_b/_x/_y/_z variants for multi-component semantics.
///
/// **glTF 2.0**: Aligns with glTF 2.0 PBR texture roles: baseColorTexture (base_color_r/g/b/a),
/// metallicRoughnessTexture (metallic = R, roughness = G), normalTexture, occlusionTexture,
/// emissiveTexture. Alpha/transparency for base color uses base_color_a; alpha mode and cutoff
/// are material attributes only (glTF material.alphaMode, material.alphaCutoff).
pub const TextureSemantic = enum(u8) {
    // Base color (glTF baseColorTexture); A channel = alpha/transparency
    base_color_r,
    base_color_g,
    base_color_b,
    base_color_a,
    // PBR metallic-roughness (glTF metallicRoughnessTexture: R = metallic, G = roughness)
    metallic,
    roughness,
    // Normal map (glTF normalTexture)
    normal_map_x,
    normal_map_y,
    normal_map_z,
    // Single-channel or generic
    occlusion, // glTF occlusionTexture
    emissive_r, // glTF emissiveTexture
    emissive_g,
    emissive_b,
};

/// Alpha blending mode for materials. Matches glTF 2.0 material.alphaMode (OPAQUE, MASK, BLEND).
pub const AlphaMode = enum(u8) {
    fully_opaque = 0, // glTF "OPAQUE"
    mask = 1, // glTF "MASK"
    blend = 2, // glTF "BLEND"
};

/// Well-known meaning of a material attribute (for default shading).
///
/// **glTF 2.0**: Aligns with glTF 2.0 pbrMetallicRoughness and material names
/// (baseColorFactor, metallicFactor, roughnessFactor, normalTextureScale,
/// occlusionTextureStrength, emissiveFactor, alphaMode, alphaCutoff).
pub const MaterialAttributeSemantic = enum(u8) {
    base_color_factor,
    metallic_factor,
    roughness_factor,
    normal_scale,
    occlusion_strength,
    emissive_factor,
    alpha_mode, // glTF material.alphaMode (use AlphaMode enum values)
    alpha_cutoff, // glTF material.alphaCutoff (used when alpha_mode == mask)
};

/// Well-known meaning of a vertex attribute stream (for default shading).
///
/// **glTF 2.0**: Aligns with glTF 2.0 mesh.primitive.attributes semantics relevant for maps.
/// POSITION is the mandatory positions buffer; these semantics name optional per-vertex
/// attributes (NORMAL, TANGENT, TEXCOORD_0/1, COLOR_0/1). Skinning (JOINTS_0, WEIGHTS_0) is omitted.
///
/// **Polylines to mesh**: For line geometry (e.g. roads), `.tangent` (along the line) and `.normal`
/// (e.g. up) can be used by a renderer to build a 3D mesh when a style specifies road width and
/// thickness, similar to how a style specifies line width for MVT.
///
/// **Recommended validation**: `.normal` and `.tangent` should be `vec3` or `vec4` numeric types;
/// `.texcoord_0` / `.texcoord_1` should be `vec2`; `.color_0` / `.color_1` should be `vec3` or `vec4`.
pub const VertexAttributeSemantic = enum(u8) {
    normal,
    tangent,
    texcoord_0,
    texcoord_1,
    color_0,
    color_1,
};

/// Binding from a material-scoped texture ID to per-channel semantics. Each of R,G,B,A can have an
/// independent semantic (null = channel unused for semantics). Enables arbitrary packing (e.g.
/// RGB = base color, or R = metallic, G = roughness in one texture).
/// **Validation**: `texture_id` **MUST** exist within `Material.textures` of the material identified by `material_id`.
pub const TextureSemanticBinding = struct {
    /// Material that contains `texture_id`.
    material_id: MaterialId,
    /// Texture ID within the referenced material.
    texture_id: TextureId,
    /// Semantic for the R channel; null if not used.
    r_component_semantic: ?TextureSemantic = null,
    /// Semantic for the G channel; null if not used.
    g_component_semantic: ?TextureSemantic = null,
    /// Semantic for the B channel; null if not used.
    b_component_semantic: ?TextureSemantic = null,
    /// Semantic for the A channel; null if not used.
    a_component_semantic: ?TextureSemantic = null,
};

/// Binding from a material-scoped attribute ID to a well-known semantic.
/// **Validation**: `attribute_id` **MUST** exist within `Material.attributes` of the material identified by
/// `material_id`.
pub const MaterialAttributeSemanticBinding = struct {
    /// Material that contains `attribute_id`.
    material_id: MaterialId,
    /// Attribute ID within the referenced material.
    attribute_id: MaterialAttributeId,
    /// Meaning of the attribute.
    semantic: MaterialAttributeSemantic,
};

/// Binding from a vertex attribute stream to a well-known semantic.
/// **Validation**: `primitive_id` **MUST** refer to `Tile3D.primitives`; `attribute_id` **MUST** exist within
/// that primitive's `vertex_buffer.attributes`.
pub const VertexAttributeSemanticBinding = struct {
    /// Primitive that contains the vertex attribute stream.
    primitive_id: PrimitiveId,
    /// Vertex attribute ID within the referenced primitive.
    attribute_id: VertexAttributeId,
    /// Meaning of the attribute stream.
    semantic: VertexAttributeSemantic,
};

/// Optional well-known semantics for a subset of textures, material attributes, and vertex attributes.
///
/// Material and vertex attributes are intentionally generic: a style sheet can read by name or ID. Some renderers
/// draw without a style sheet and without project-specific names; for them the tile can provide `TileSemantics`,
/// which assigns well-known semantics so the renderer can apply default shading. Bindings must reference
/// texture/attribute IDs that exist within the referenced material (or primitive); see the binding types above.
pub const TileSemantics = struct {
    texture_semantics: []const TextureSemanticBinding = &[_]TextureSemanticBinding{},
    material_attribute_semantics: []const MaterialAttributeSemanticBinding = &[_]MaterialAttributeSemanticBinding{},
    vertex_attribute_semantics: []const VertexAttributeSemanticBinding = &[_]VertexAttributeSemanticBinding{},
};

/// Vertex buffer: optional indices, positions, and per-vertex attributes.
///
/// **Validation**: Every entry in `attributes` **MUST** have the same `element_count` as `positions.element_count`.
/// If `indices` is present, `indices.element_count` **MUST** be a valid index stream length for the
/// primitive's `topology`
/// (for example, a multiple of 3 for `triangles` when not using strips).
pub const VertexBuffer = struct {
    /// Optional index buffer.
    /// When absent, vertices are used in the order stored in `positions`.
    indices: ?IndexBuffer,
    /// Vertex positions.
    positions: PositionsBuffer,
    /// Optional per-vertex attribute streams (normals, UVs, tangents, colors, custom attrs).
    attributes: []const VertexAttribute,
};

/// One drawable geometry unit.
///
/// **Validation**: `id` **MUST** be unique within `Tile3D.primitives`. When present, `material_id` **MUST**
/// refer to an entry in `Tile3D.materials`.
pub const Primitive3D = struct {
    /// Must be unique within `Tile3D.primitives`.
    id: PrimitiveId,
    name: ?Utf8String = null,
    topology: Topology,
    /// When present, must refer to an entry in `Tile3D.materials`.
    material_id: ?MaterialId = null,
    /// Optional bounding volume in primitive-local space (for culling and LOD).
    bounding_volume: ?BoundingVolume = null,
    vertex_buffer: VertexBuffer,
};

/// Reference to a primitive plus an optional local transform into object space.
/// **Validation**: `primitive_id` **MUST** refer to an entry in `Tile3D.primitives`. When
/// `primitive_to_object` is null, identity is used.
pub const PrimitiveInstance = struct {
    /// Must refer to an entry in `Tile3D.primitives`.
    primitive_id: PrimitiveId,
    /// When null, this transform is interpreted as identity.
    primitive_to_object: ?Transform,
};

/// Named collection of primitive instances.
/// **Validation**: `id` **MUST** be unique within `Tile3D.objects`.
pub const Object3D = struct {
    /// Must be unique within `Tile3D.objects`.
    id: ObjectId,
    name: ?Utf8String = null,
    /// Optional bounding volume in object-local space (for culling and LOD).
    bounding_volume: ?BoundingVolume = null,
    /// List of primitives that make up this object.
    /// Each entry can optionally apply a local transform from primitive space to object space.
    primitive_instances: []const PrimitiveInstance,
};

/// Placement of an object into tile space.
/// **Validation**: `object_id` **MUST** refer to an entry in `Tile3D.objects`. When `object_to_tile` is
/// null, identity is used.
pub const ObjectInstance = struct {
    /// Must refer to an entry in `Tile3D.objects`.
    object_id: ObjectId,
    /// When null, this transform is interpreted as identity.
    object_to_tile: ?Transform,
    /// Optional feature ID for per-feature metadata in `Tile3D.feature_table`.
    feature_id: ?FeatureId = null,
};

/// Level-of-detail (LOD) grouping.
///
/// **Validation**: `object_id` **MUST** refer to an entry in `Tile3D.objects`. When `variant_to_group` is
/// null, identity is used.
///
/// Note: In map rendering, zoom-level tiling is typically the primary LOD mechanism.
/// This schema also supports intra-tile LOD groups to provide additional 3D-specific
/// control (e.g. dense meshes, impostors/billboards, and continuous 3D camera views).
pub const LodVariant = struct {
    /// Must refer to an entry in `Tile3D.objects`.
    object_id: ObjectId,
    /// When null, this transform is interpreted as identity.
    /// Use a non-identity transform when a variant has a different pose or origin within the group
    /// (e.g. an impostor/billboard variant offset or scaled relative to the full-detail model).
    variant_to_group: ?Transform = null,
    /// Variant ordering hint only; selection is client-defined.
    /// Rank 0 is the most detailed / preferred; higher ranks are coarser.
    rank: u8,
    /// Optional geometric error for this LOD variant (same units as tile coordinates).
    /// When present, clients may use it together with view distance to choose which variant to display.
    geometric_error: ?Float = null,
};

/// Instance of an LOD group placed in tile space.
pub const LodGroupInstance = struct {
    /// When null, this transform is interpreted as identity.
    group_to_tile: ?Transform,
    /// Variant ordering hint only; selection is client-defined.
    /// Rank 0 is typically the most detailed; higher ranks are coarser.
    variants: []const LodVariant,
    /// Optional deterministic fallback for clients that want a default.
    /// When present, must equal one of the variant `rank` values.
    default_variant_rank: ?u8 = null,
    /// Optional feature ID for per-feature metadata in `Tile3D.feature_table`.
    feature_id: ?FeatureId = null,
};

/// Scene item union.
///
/// A tile scene is a flat list of items rather than a nested tree.
pub const SceneItem = union(enum) {
    /// A single object instance placed in tile space.
    object: ObjectInstance,
    /// A level-of-detail (LOD) group instance placed in tile space.
    lod_group: LodGroupInstance,
};

// --- Per-feature / per-instance metadata (feature table) ---
//
// Column-oriented layout aligned with MLT 2D: one optional id column and property columns.
/// Value of a single feature property (for styling, query, and analysis).
pub const FeaturePropertyValue = union(enum) {
    scalar: ScalarValue,
    vec2: [2]ScalarValue,
    vec3: [3]ScalarValue,
    vec4: [4]ScalarValue,
    /// UTF-8 string (e.g. names, identifiers, categories).
    string: Utf8String,
};

/// One property of a feature (feature_id + name + value). Multiple `Feature` entries can share the
/// same `feature_id` for multiple properties. Scene items reference a feature by `feature_id`.
/// These properties define attributes a **styling tool** can use (e.g. for filters, colors, labels).
pub const Feature = struct {
    /// ID of the feature; referenced by `ObjectInstance.feature_id` and `LodGroupInstance.feature_id`.
    feature_id: FeatureId,
    /// Property name.
    name: Utf8String,
    /// Property value.
    value: FeaturePropertyValue,
};

/// Top-level tile payload.
///
/// **Validation (normative)**. A producer **MUST** satisfy these; a consumer/validator **MUST** reject
/// tiles that do not:
/// - **ID uniqueness**: `Primitive3D.id` unique within `primitives`; `Object3D.id` within `objects`;
///   `Material.id` within `materials`; `MaterialAttribute.id` within each material's `attributes`;
///   `Texture.id` within each material's `textures`; `VertexAttribute.id` within each primitive's
///   `vertex_buffer.attributes`.
/// - **Referential integrity**: Every `PrimitiveInstance.primitive_id` and `ObjectInstance.object_id`
///   (and LOD variant `object_id`) **MUST** refer to an existing entry; `Primitive3D.material_id` when
///   present **MUST** refer to `materials`. Every `ObjectInstance.feature_id` and
///   `LodGroupInstance.feature_id` when present **MUST** equal at least one `Feature.feature_id` in
///   `features`.
/// See the doc comments on each type for stride, encoding, element count, and semantic binding rules.
pub const Tile3D = struct {
    /// Tile bounds/size (MVT-aligned integer extent units; see `TileExtents` and module doc).
    extents: TileExtents,

    /// Optional geometric error for this tile (same units as tile coordinates / MVT extent space).
    /// Used by clients for LOD/refinement: when the projected error exceeds a threshold, a more detailed
    /// tile or variant may be requested.
    geometric_error: ?Float = null,

    /// Optional semantic bindings (see `TileSemantics`).
    semantics: ?TileSemantics = null,
    /// Optional features: properties attached to objects via `feature_id`; usable by styling tools.
    features: []const Feature,
    /// Materials used by primitives.
    materials: []const Material,
    /// Geometry primitives.
    primitives: []const Primitive3D,
    /// Named primitive groupings.
    objects: []const Object3D,

    /// Scene: flat list of object instances and/or LOD group instances (no hierarchy).
    scene: []const SceneItem,
};
