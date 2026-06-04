/// Dart port of the engine's win geometry (spec §3.4 lines, §5 Morph shapes), used by the pure-Dart
/// mock backend. Mirrors `engine/src/geometry.rs`; the native backend uses the Rust original.
library;

/// All length-3 winning segments for a `rows×cols` grid: horizontal, vertical, both diagonals.
List<List<int>> lineTriples(int rows, int cols) {
  int idx(int r, int c) => r * cols + c;
  final out = <List<int>>[];
  const dirs = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      for (final d in dirs) {
        final r2 = r + 2 * d[0];
        final c2 = c + 2 * d[1];
        if (r2 < 0 || r2 >= rows || c2 < 0 || c2 >= cols) continue;
        out.add([idx(r, c), idx(r + d[0], c + d[1]), idx(r2, c2)]);
      }
    }
  }
  return out;
}

// ---- Morph shapes ----

List<List<int>> _baseShapes() => [
      [0, 0, 0, 1, 0, 2, 0, 3], // I  (flattened (r,c) pairs)
      [0, 0, 1, 0, 2, 0, 2, 1], // L
      [0, 1, 0, 2, 1, 0, 1, 1], // Z
    ];

List<List<int>> _toPairs(List<int> flat) {
  final pairs = <List<int>>[];
  for (var i = 0; i < flat.length; i += 2) {
    pairs.add([flat[i], flat[i + 1]]);
  }
  return pairs;
}

List<List<int>> _normalize(List<List<int>> s) {
  final minR = s.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
  final minC = s.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
  final out = s.map((p) => [p[0] - minR, p[1] - minC]).toList();
  out.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
  return out;
}

List<List<int>> _rotate(List<List<int>> s) => s.map((p) => [p[1], -p[0]]).toList();
List<List<int>> _mirror(List<List<int>> s) => s.map((p) => [p[0], -p[1]]).toList();

String _key(List<List<int>> s) => s.map((p) => '${p[0]},${p[1]}').join(';');

List<List<List<int>>> _orientations(List<List<int>> base) {
  final seen = <String>{};
  final out = <List<List<int>>>[];
  var cur = base;
  for (var i = 0; i < 4; i++) {
    for (final v in [cur, _mirror(cur)]) {
      final n = _normalize(v);
      final k = _key(n);
      if (seen.add(k)) out.add(n);
    }
    cur = _rotate(cur);
  }
  return out;
}

/// Placement basis: how the shape's own (row, col) axes map onto the grid.
///   - [rowStep] is the grid step for one step along the shape's row axis.
///   - [colStep] is the grid step for one step along the shape's column axis.
class _Basis {
  final List<int> rowStep;
  final List<int> colStep;
  const _Basis(this.rowStep, this.colStep);
}

/// Axis-aligned frame (the classic placement): shape-right → grid-right, shape-down → grid-down.
const _axis = _Basis([1, 0], [0, 1]);

/// 45°-rotated frame: shape-down → grid down-left, shape-right → grid down-right. Laying a shape on
/// this frame yields its staircase / **diagonal** placements (e.g. the diagonal I), which the
/// axis frame can never produce. This is what makes Morph recognise diagonal shapes (spec §5 — the
/// diagonal exclusion was reversed during play-testing per §13.1: diagonals are IN).
const _diag = _Basis([1, -1], [1, 1]);

/// All concrete 4-cell placements of a SINGLE Morph shape (`shapeIndex`: 0=I, 1=L, 2=Z) on a
/// `rows×cols` grid.
///
/// Morph-only generalization: each of the shape's orientations (4 rotations + mirror, on its own
/// relative cells) is laid onto the grid under BOTH the [_axis] and [_diag] bases, anchored at every
/// cell, bounds-checked, and deduped — giving axis-aligned AND diagonal placements. Line modes are
/// unaffected (they use [lineTriples]). In Morph one shape is chosen at game start and the win is to
/// complete that shape in any of these placements (spec §4.4, §5).
List<List<int>> morphPlacementsForShape(int rows, int cols, int shapeIndex) {
  final placements = <List<int>>[];
  final seen = <String>{};
  final base = _toPairs(_baseShapes()[shapeIndex]);

  for (final orient in _orientations(base)) {
    for (final b in const [_axis, _diag]) {
      // 1. Map the shape into grid-space under this basis.
      var t = orient
          .map((p) => [
                p[0] * b.rowStep[0] + p[1] * b.colStep[0],
                p[0] * b.rowStep[1] + p[1] * b.colStep[1],
              ])
          .toList();
      // 2. Normalize: shift min row/col to 0. CRITICAL — the diagonal basis produces negative
      //    coordinates for top-left placements; without this shift those placements would need a
      //    negative anchor and be silently dropped (asymmetric: top-left missing, bottom-right ok).
      final minR = t.map((p) => p[0]).reduce((a, x) => a < x ? a : x);
      final minC = t.map((p) => p[1]).reduce((a, x) => a < x ? a : x);
      t = t.map((p) => [p[0] - minR, p[1] - minC]).toList();
      final maxR = t.map((p) => p[0]).reduce((a, x) => a > x ? a : x);
      final maxC = t.map((p) => p[1]).reduce((a, x) => a > x ? a : x);
      if (maxR >= rows || maxC >= cols) continue;
      // 3. Slide the normalized shape over every valid anchor.
      for (var offR = 0; offR <= rows - 1 - maxR; offR++) {
        for (var offC = 0; offC <= cols - 1 - maxC; offC++) {
          final cells = t.map((p) => (offR + p[0]) * cols + (offC + p[1])).toList()..sort();
          final k = cells.join(',');
          if (seen.add(k)) placements.add(cells);
        }
      }
    }
  }
  return placements;
}
