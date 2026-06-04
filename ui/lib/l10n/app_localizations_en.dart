// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuLabel => 'Menu';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get navIssue => 'Issue';

  @override
  String get homeHint => 'Tap a side to play';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Futuristic XOX began as a simple question: what if the humble tic-tac-toe pawns had weight? Here they carry numbers and can capture one another, classic X/O play lives on as its own mode, and a few twists — randomized hands, shape-completion — keep every match fresh. Built with care for a smooth, premium feel. Have fun, and may the better tactician win.';

  @override
  String get issueTitle => 'Issue';

  @override
  String get issueFaq => 'FAQ';

  @override
  String get issueFaqItem => 'Question';

  @override
  String get issueFaqSoon => 'The answer to this one is coming soon.';

  @override
  String get issueContact => 'Contact';

  @override
  String get issueContactNote =>
      'Found a bug or have a suggestion? We\'d love to hear from you.';

  @override
  String get tapToPlay => 'Tap to play';

  @override
  String get classicTagline => 'Silver × Gold';

  @override
  String get futuristicTagline => 'Capture · Conquer';

  @override
  String get modeClassic => 'Classic';

  @override
  String get modeFuturistic => 'Futuristic';

  @override
  String get chooseMode => 'Choose a mode';

  @override
  String get modeOriginal => 'Original';

  @override
  String get modeOriginalDesc => 'Classic flow with valued pawns & capture';

  @override
  String get modeBonanza => 'Bonanza';

  @override
  String get modeBonanzaDesc => 'Randomized starting hands — luck of the draw';

  @override
  String get modeMorph => 'Morph';

  @override
  String get modeMorphDesc => 'Complete a 4-cell shape to win';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get gridLabel => 'Grid';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get startButton => 'Start';

  @override
  String get offlineMpTitle => 'Offline Multiplayer';

  @override
  String get offlineMpOn => 'Two players · same device';

  @override
  String get offlineMpOff => 'Play vs computer';

  @override
  String get playerYou => 'You';

  @override
  String get playerComputer => 'Computer';

  @override
  String get player1 => 'Player 1';

  @override
  String get player2 => 'Player 2';

  @override
  String get turnSuffix => 'turn';

  @override
  String moveOfTwo(int n) {
    return 'move $n of 2';
  }

  @override
  String get captureMsg => 'Capture!';

  @override
  String get noSecondMove => 'No second move available — turn passes';

  @override
  String get selectPawnFirst => 'Select a pawn first';

  @override
  String resultWins(String name) {
    return '$name wins!';
  }

  @override
  String get resultDraw => 'Draw';

  @override
  String get target => 'Target';

  @override
  String get anyRotation => 'any rotation';

  @override
  String get restart => 'Restart';

  @override
  String get menuButton => 'Menu';

  @override
  String get playAgain => 'Play again';

  @override
  String get yourHand => 'YOUR HAND';

  @override
  String bonanzaHandLine(int own, int total, int opp) {
    return '$own of your $total pawns are your own colour\n($opp are your opponent\'s)';
  }

  @override
  String get tutSkip => 'Skip';

  @override
  String get tutHintGlow => 'Tap the glowing square';

  @override
  String get tutHintWrong => 'Not there — place it on the glowing square';

  @override
  String get tutHintGreat => 'Nice!';

  @override
  String get tutCapH => 'Horizontal';

  @override
  String get tutCapV => 'Vertical';

  @override
  String get tutCapD => 'Diagonal';

  @override
  String get tutBtnStart => 'Let\'s begin';

  @override
  String get tutBtnOk => 'Got it';

  @override
  String get tutBtnTry => 'Let\'s try';

  @override
  String get tutBtnFinish => 'Finish';

  @override
  String get tutClassicWelcomeTitle => 'Welcome';

  @override
  String get tutClassicWelcomeBody =>
      'Good to have you here. We\'ll learn this board together in a moment — no rush, step by step, side by side. Ready when you are.';

  @override
  String get tutClassicTurnTitle => 'Your turn to start';

  @override
  String get tutClassicTurnBody =>
      'When it\'s your turn you drop an X on the board. Watch — an X lands on the glowing square.';

  @override
  String get tutClassicDemo1Title => 'Now you try';

  @override
  String get tutClassicDemo1Body =>
      'Tap the glowing square and place your first X. (Any empty square works too.)';

  @override
  String get tutClassicDemo1Hint => 'Tap the glowing square';

  @override
  String get tutClassicWinruleTitle => 'The one secret to winning';

  @override
  String get tutClassicWinruleBody =>
      'Line up three X\'s — horizontal, vertical, or diagonal, it doesn\'t matter. Complete the line and you win.';

  @override
  String get tutClassicDemo2aTitle => '1 / 3 — Horizontal';

  @override
  String get tutClassicDemo2aBody =>
      'Two X\'s are lined up. Complete the glowing square and close the horizontal line.';

  @override
  String get tutClassicDemo2bTitle => '2 / 3 — Vertical';

  @override
  String get tutClassicDemo2bBody =>
      'This time we complete the column. Place an X on the glowing square.';

  @override
  String get tutClassicDemo2cTitle => '3 / 3 — Diagonal';

  @override
  String get tutClassicDemo2cBody =>
      'Finally, the diagonal. Place an X on the glowing center square to complete the trio.';

  @override
  String get tutClassicDoneTitle => 'That\'s all it takes!';

  @override
  String get tutClassicDoneBody =>
      'The Classic board is all yours now. Jump into a real game whenever you like — good luck, and may you be the one who wins.';

  @override
  String get tutLaunch => 'How to play';

  @override
  String get navTutorials => 'Tutorials';

  @override
  String get tutSoon => 'Coming soon';
}
