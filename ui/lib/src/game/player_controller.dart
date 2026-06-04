import '../models/game_models.dart';

/// Who supplies moves for a seat at the table. The game loop asks the **active seat's** controller
/// for its move and applies it; the engine never knows whether a player is human, AI, or remote.
///
/// This is the seam that makes the same board/engine serve single-player, offline multiplayer, and
/// (later) online play — only the mode→controller mapping changes (spec: Offline Multiplayer feature).
abstract class PlayerController {
  /// Display name for this seat (turn indicator + rail). A placeholder now ("You", "Computer",
  /// "Player 1/2"); later an editable name (offline) or a real nickname (online) — sourced from here
  /// so a future swap touches one place.
  String get label;

  /// True if moves come from local UI input; false if produced programmatically (AI / remote).
  bool get isHuman;
}

/// A human playing via local UI input (tap a rail pawn, then a board cell).
class HumanController extends PlayerController {
  @override
  final String label;
  HumanController(this.label);

  @override
  bool get isHuman => true;
}

/// The computer, playing through the AI layer at a given difficulty.
class AiController extends PlayerController {
  final Difficulty difficulty;
  @override
  final String label;
  AiController(this.difficulty, {this.label = 'Computer'});

  @override
  bool get isHuman => false;
}

// Future seam — online play: a `RemoteController` (isHuman == false) would resolve moves from a
// network connection and fill `label` from the peer's nickname. Not implemented yet.
