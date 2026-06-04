import 'package:flutter/foundation.dart';

import 'tutorial_step.dart';

/// Drives a tutorial: holds the current [stepIndex] and advances through [steps] (spec §0). Reusable
/// across modes — only the steps differ. Exit (skip / finish) is handled by the screen via a callback.
class TutorialController extends ChangeNotifier {
  final List<TutorialStep> steps;
  int stepIndex = 0;

  TutorialController({required this.steps});

  TutorialStep get current => steps[stepIndex];
  bool get isLast => stepIndex == steps.length - 1;
  bool get isFirst => stepIndex == 0;
  int get count => steps.length;

  /// Advance to the next step (no-op on the last step — the screen exits instead).
  void next() {
    if (!isLast) {
      stepIndex++;
      notifyListeners();
    }
  }

  void restart() {
    stepIndex = 0;
    notifyListeners();
  }
}
