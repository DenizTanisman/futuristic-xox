// Win-line path ordering tests. Run with `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/src/widgets/win_line.dart';

/// Every consecutive pair in a continuous polyline must be a side or diagonal neighbour.
void expectContinuous(List<int> path, int cols, List<int> cells) {
  expect(path.toSet(), cells.toSet(), reason: 'path must contain exactly the winning cells');
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1], b = path[i];
    final dr = (a ~/ cols - b ~/ cols).abs();
    final dc = (a % cols - b % cols).abs();
    expect(dr <= 1 && dc <= 1 && a != b, isTrue,
        reason: 'cells $a and $b are not adjacent in $path');
  }
}

void main() {
  test('3-in-a-row stays in natural order', () {
    expect(orderWinPath([0, 1, 2], 3), [0, 1, 2]);
    expect(orderWinPath([0, 4, 8], 3), [0, 4, 8]); // diagonal
  });

  test('Morph vertical I [1,5,9,13] is one continuous chain (4x4)', () {
    expectContinuous(orderWinPath([1, 5, 9, 13], 4), 4, [1, 5, 9, 13]);
  });

  test('Morph horizontal I [4,5,6,7] is continuous', () {
    expectContinuous(orderWinPath([4, 5, 6, 7], 4), 4, [4, 5, 6, 7]);
  });

  test('Morph diagonal L [0,5,10,13] is continuous', () {
    expectContinuous(orderWinPath([0, 5, 10, 13], 4), 4, [0, 5, 10, 13]);
  });

  test('Morph diagonal Z [1,3,4,6] is continuous (zigzag through diagonal neighbours)', () {
    // Endpoints are 3 and 4; the only continuous order is 3-6-1-4 (or its reverse).
    final path = orderWinPath([1, 3, 4, 6], 4);
    expectContinuous(path, 4, [1, 3, 4, 6]);
    expect(path.first == 3 || path.first == 4, isTrue);
    expect(path.last == 3 || path.last == 4, isTrue);
  });

  test('order is independent of input order (set in, path out)', () {
    expectContinuous(orderWinPath([13, 1, 9, 5], 4), 4, [1, 5, 9, 13]);
    expectContinuous(orderWinPath([6, 4, 1, 3], 4), 4, [1, 3, 4, 6]);
  });
}
