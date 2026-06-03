/// Dart port of the engine's win geometry (spec §3.4 lines, §5 Morph shapes), used by the pure-Dart
/// mock backend. Mirrors `engine/src/geometry.rs`; the native backend uses the Rust original.

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

/// Every concrete 4-cell Morph placement on a `rows×cols` grid (all I/L/Z rotations + mirror, slid
/// over the grid, deduped). Excludes the pure diagonal (spec §5).
List<List<int>> morphPlacements(int rows, int cols) {
  final placements = <List<int>>[];
  final seen = <String>{};
  for (final flat in _baseShapes()) {
    for (final orient in _orientations(_toPairs(flat))) {
      final maxR = orient.map((p) => p[0]).reduce((a, b) => a > b ? a : b);
      final maxC = orient.map((p) => p[1]).reduce((a, b) => a > b ? a : b);
      if (maxR >= rows || maxC >= cols) continue;
      for (var offR = 0; offR < rows - maxR; offR++) {
        for (var offC = 0; offC < cols - maxC; offC++) {
          final cells = orient.map((p) => (offR + p[0]) * cols + (offC + p[1])).toList()..sort();
          final k = cells.join(',');
          if (seen.add(k)) placements.add(cells);
        }
      }
    }
  }
  return placements;
}
