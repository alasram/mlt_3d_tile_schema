//! 3D tile schema (draft)
//!
//! This file defines the schema types for a simple, renderer-friendly 3D tile format
//! designed to be used alongside MVT (Mapbox Vector Tiles) in MLT (MapLibre Tile format).
//!
//! ## Goals
//!
//! - Simple and MVT-aligned: one tile payload per zoom/x/y, flat scene, feature properties
//!   for styling — the same mental model as MVT.
//! - Style-driven appearance: the tile carries geometry and data; the style sheet controls
//!   all visual presentation (color, opacity, shading, etc.), just like MVT.
//! - Fixed vertex attribute types with optional banking angles and custom attributes
//!   for data-driven styling.
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
//! - `primitives`: geometry units (topology + vertex buffer).
//! - `imports`: import table for referencing primitives from external Asset Libraries.
//! - `objects`: named collections of primitive IDs placed in tile space via `ObjectInstance`.
//! - `features`: per-object properties for styling (filters, colors, labels).
//! - `scene`: flat list of `ObjectInstance` values.
//!
//! ## Styling
//!
//! The style sheet references primitives and objects directly and controls their appearance
//! (color, opacity, visibility, extrusion width, etc.). This follows the same approach as
//! MVT: the tile carries data and geometry; the style sheet controls all visual presentation.
//! Everything is style-driven — primitives with no matching style rule are not rendered.
//!
//! ## Asset Library
//!
//! Shared assets like trees and poles can be stored in a separate MLT file and shared across
//! many tiles. An Asset Library is itself an MLT3DScene (same schema, just used as a shared
//! pool rather than a renderable tile). A tile references external primitives via the import
//! table, which maps each external primitive to a local PrimitiveId within the tile.
//!
//! ## Type simplification
//!
//! All integer types use i32 or u32 unless MVT interop requires otherwise. MLT applies
//! per-column compression (e.g. delta encoding, bit-packing) so small-range values are
//! packed efficiently at the encoding layer.

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
// Primitive types
// ----------------------------------------------------------------------------

/// 3D signed 32-bit integer vector. Used for vertex positions.
pub const Vec3i32 = struct { x: i32, y: i32, z: i32 };

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
/// Local and imported PrimitiveIds share the same namespace within a tile.
pub const PrimitiveId = u32;
/// Feature identifier; unique within `MLT3DScene.features`.
pub const FeatureId = u32;

/// UTF-8 encoded string.
pub const Utf8String = []const u8;

// ----------------------------------------------------------------------------
// Custom vertex attributes
// ----------------------------------------------------------------------------

/// Value type for a custom vertex attribute.
pub const CustomAttributeType = enum(u8) {
    i32 = 0,
    f32 = 1,
};

/// A named per-vertex attribute array with a uniform scalar type.
///
/// Custom attributes let producers encode data values (e.g. temperature, elevation,
/// road width) that the style sheet maps to visual properties (color ramps, opacity, size).
/// The schema assigns no semantics to custom attributes; the style sheet is the sole interpreter.
///
/// For vector-valued data (e.g. wind direction), producers use multiple scalar attributes
/// (e.g. "wind_x", "wind_y", "wind_z").
pub const CustomAttribute = struct {
    /// Attribute name referenced by the style sheet.
    name: Utf8String,
    /// Value type for all elements in `data`.
    attribute_type: CustomAttributeType,
    /// Raw bytes: vertex_count × 4 bytes (i32 or f32, little-endian).
    data: []const u8,
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
/// - positions:      vertex_count × 12 bytes (3 × i32)
/// - banking_angles: vertex_count × 4 bytes  (1 × i32, tenths of a degree)
///
/// **Validation**:
/// - All present attribute buffers MUST contain exactly `vertex_count` elements.
/// - `banking_angles`: optional i32 per vertex (tenths of a degree, e.g. 450 = 45.0°).
///   Only valid for `lines` and `line_strip` topologies; ignored or rejected on others.
///   Specifies rotation around the line's tangent direction. Zero means horizontal (flat road).
///   Positive values tilt clockwise when looking in the forward direction.
///   When present, enables road ribbon creation. When absent, only a stroke can be drawn.
/// - `custom_attributes`: each attribute array MUST contain exactly `vertex_count` elements.
pub const VertexBuffer = struct {
    /// Optional index buffer. When absent, vertices are drawn in sequential order.
    indices: ?IndexBuffer = null,

    /// Number of vertices. All present attribute buffers must contain this many elements.
    vertex_count: u32,

    /// Positions: vec3i32. Required. Values outside [0, extent) are valid (outside tile bounds).
    positions: []const u8,

    /// Banking angles: i32. Optional. Tenths of a degree (e.g. 450 = 45.0°).
    /// Only valid for `lines` and `line_strip` topologies.
    /// Specifies rotation around the line's tangent direction for road ribbons.
    banking_angles: ?[]const u8 = null,

    /// Custom per-vertex attribute arrays. Optional.
    /// Each attribute has a name, type (i32 or f32), and data array with vertex_count elements.
    /// The style sheet interprets these (e.g. mapping "temperature" to a color ramp).
    custom_attributes: []const CustomAttribute = &[_]CustomAttribute{},
};

// ----------------------------------------------------------------------------
// Asset Library imports
// ----------------------------------------------------------------------------

/// An entry in the import table referencing a primitive from an external Asset Library.
///
/// The style sheet declares Asset Libraries (mapping library names to URLs) the same way
/// it declares glyphs and sprite sheets. The tile only carries the library name, not the URL.
///
/// **Validation**: `local_id` MUST be unique within the tile (no collision with local
/// primitive IDs or other import local IDs). `library_primitive_id` refers to a PrimitiveId
/// within the external Asset Library.
pub const AssetImport = struct {
    /// Name of the Asset Library (matched against style sheet declarations).
    library_name: Utf8String,
    /// PrimitiveId within the external Asset Library.
    library_primitive_id: PrimitiveId,
    /// Local PrimitiveId assigned within the importing tile.
    /// Object3D.primitive_ids references this ID like any local primitive.
    local_id: PrimitiveId,
};

// ----------------------------------------------------------------------------
// Primitives and objects
// ----------------------------------------------------------------------------

/// One drawable geometry unit: topology and vertex buffer.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.primitives`.
pub const Primitive3D = struct {
    /// Unique within `MLT3DScene.primitives`.
    id: PrimitiveId,
    topology: Topology,
    vertex_buffer: VertexBuffer,
};

/// Named collection of primitives placed in tile space via `ObjectInstance`.
/// Object names correspond to MVT layer names — an Object3D named "buildings" is the 3D
/// counterpart of the MVT layer named "buildings". Names are required and unique within the
/// 3D frame, matching MVT's requirement that layer names are required and unique.
///
/// **Validation**: `id` MUST be unique within `MLT3DScene.objects`.
/// `name` MUST be unique within `MLT3DScene.objects`.
/// Every entry in `primitive_ids` MUST refer to a local primitive (from `MLT3DScene.primitives`)
/// or an imported primitive (from `MLT3DScene.imports`).
pub const Object3D = struct {
    /// Unique within `MLT3DScene.objects`.
    id: ObjectId,
    /// Required. Corresponds to MVT layer name for style sheet targeting and 2D/3D correlation.
    name: Utf8String,
    /// Primitives that make up this object, referenced by ID.
    /// May reference both local primitives and imported primitives (via their local_id).
    primitive_ids: []const PrimitiveId,
};

// ----------------------------------------------------------------------------
// Scene
// ----------------------------------------------------------------------------

/// Placement of an object into tile space.
///
/// Multiple instances may share the same `feature_id`, allowing the style sheet to apply
/// the same styling (e.g. highlight color) to all instances of the same logical entity.
///
/// **Validation**: `object_id` MUST refer to an entry in `MLT3DScene.objects`.
/// When `feature_id` is present it MUST refer to an entry in `MLT3DScene.features`.
pub const ObjectInstance = struct {
    /// Must refer to an entry in `MLT3DScene.objects`.
    object_id: ObjectId,
    /// Transform from object space to tile space. When null, identity is assumed.
    object_to_tile: ?Mat4x4f32 = null,
    /// Optional link to per-feature metadata in `MLT3DScene.features`.
    feature_id: ?FeatureId = null,
};

// ----------------------------------------------------------------------------
// Features
// ----------------------------------------------------------------------------

/// Value of a single feature property. Used by styling tools for filtering, coloring, and labeling.
pub const FeaturePropertyValue = union(enum) {
    bool: bool,
    /// Signed integer value. i64 matches MVT sint64/uint64 range for lossless interop.
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
///   `objects`; `Object3D.name` unique within `objects`; `Feature.id` within `features`.
///   `AssetImport.local_id` unique and non-colliding with local primitive IDs.
///   `FeatureProperty.name` is NOT required to be unique within a feature (following MVT conventions).
/// - **Referential integrity**: Every `Object3D.primitive_ids` entry MUST refer to an existing
///   local primitive or an imported primitive (by `local_id`). Every `ObjectInstance.object_id`
///   MUST refer to an existing object. `ObjectInstance.feature_id` when present MUST refer to
///   an existing feature.
/// - **Banking angles**: `VertexBuffer.banking_angles` MUST only be present for `lines` and
///   `line_strip` topologies.
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

    /// Geometry primitives defined locally in this tile.
    primitives: []const Primitive3D,

    /// Import table for referencing primitives from external Asset Libraries.
    /// Each entry maps an external primitive to a local PrimitiveId within this tile.
    imports: []const AssetImport = &[_]AssetImport{},

    /// Named collections of primitives. Placed into the scene via `ObjectInstance`.
    objects: []const Object3D,

    /// Per-object properties for styling (filters, colors, labels). Aligned with MVT feature model.
    features: []const Feature,

    /// Scene: flat list of object instances in tile space.
    scene: []const ObjectInstance,
};
