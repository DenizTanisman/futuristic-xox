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
  String get settingsSfx => 'Sound Effects';

  @override
  String get settingsSfxVolume => 'Volume';

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

  @override
  String get tutBtnNext => 'Continue';

  @override
  String get tutRailLabel => 'Your pawns';

  @override
  String get tutHintSelect => 'Pick a pawn first';

  @override
  String get tutHintPlaceNow => 'Now tap a square';

  @override
  String get tutHintEat => 'Pick a pawn, then tap the center opponent pawn';

  @override
  String get tutHintWinPlace => 'Pick a pawn, then tap the glowing square';

  @override
  String get tutHintEatwin =>
      'Pick a pawn bigger than 5, then place it in the center';

  @override
  String get tutHintSmall => 'Too small — pick a bigger pawn';

  @override
  String get tutHintRedirect => 'Place it on the glowing square';

  @override
  String get tutHintWin => 'You win!';

  @override
  String get tutOrigWelcomeTitle => 'Welcome to Futuristic';

  @override
  String get tutOrigWelcomeBody =>
      'You\'re about to play tic-tac-toe like you\'ve never seen it. No rush — we\'ll discover the new rules together, step by step. Ready when you are.';

  @override
  String get tutOrigNumbersTitle => 'Now there are numbers';

  @override
  String get tutOrigNumbersBody =>
      'You no longer place just X or O. Instead you place valued numbers — and each one carries a power. That small change changes everything.';

  @override
  String get tutOrigPlaceTitle => 'Place any pawn you like';

  @override
  String get tutOrigPlaceBody =>
      'You can drop any of your pawns on an empty square. Watch — a gold pawn lands on the glowing square.';

  @override
  String get tutOrigDemoplaceTitle => 'Now you try';

  @override
  String get tutOrigDemoplaceBody =>
      'First pick a pawn below, then tap an empty square to place it.';

  @override
  String get tutOrigCapintroTitle => 'You can capture, too';

  @override
  String get tutOrigCapintroBody =>
      'Here\'s the fun part: you can capture your opponent\'s pawn. Watch — a larger gold pawn lands on theirs and takes it.';

  @override
  String get tutOrigCapruleTitle => 'But there\'s one rule';

  @override
  String get tutOrigCapruleBody =>
      'To capture a pawn, yours must have a strictly greater value. A smaller pawn can\'t take a larger one.';

  @override
  String get tutOrigDemoeatTitle => 'Now you capture';

  @override
  String get tutOrigDemoeatBody =>
      'Try to capture the opponent pawn (3) in the center. First with a small pawn — then with one that\'s big enough.';

  @override
  String get tutOrigWinruleTitle => 'How you win';

  @override
  String get tutOrigWinruleBody =>
      'Winning is still familiar: line up three of your own pawns — horizontal, vertical, or diagonal. It\'s the line that matters, not the values.';

  @override
  String get tutOrigDemowinTitle => 'Complete the line';

  @override
  String get tutOrigDemowinBody =>
      'Place a pawn on the glowing empty square and complete the right-column trio.';

  @override
  String get tutOrigDemoeatwinTitle => 'Capture and win at once';

  @override
  String get tutOrigDemoeatwinBody =>
      'This time your winning move also captures. Pick a pawn big enough to take the opponent\'s 5 in the center, place it there, and close the diagonal.';

  @override
  String get tutOrigDoneTitle => 'That\'s Original!';

  @override
  String get tutOrigDoneBody =>
      'Now you know the power of numbers, capturing, and winning. Try it in a real game — be the one who wins.';

  @override
  String get tutBonWelcomeTitle => 'Welcome to Bonanza';

  @override
  String get tutBonWelcomeBody =>
      'This is where luck joins the game. We\'ll uncover this mode\'s twist together in a few turns — don\'t worry, the fun part is close.';

  @override
  String get tutBonOriginalTitle => 'First, the basics';

  @override
  String get tutBonOriginalBody =>
      'You place pawns and win by lining up three of yours — just like in Original. If you haven\'t learned that yet, drop by there first.';

  @override
  String get tutBonHookTitle => 'What if…';

  @override
  String get tutBonHookBody =>
      'what if you held some of your opponent\'s pawns from the very start? 🙂 That\'s exactly what Bonanza does.';

  @override
  String get tutBonRandomTitle => 'It all starts with a number';

  @override
  String get tutBonRandomBody =>
      'In Bonanza a random number is drawn at the start of every game. It decides how many of your own pawns you\'ll hold.';

  @override
  String get tutBonLuckTitle => 'The rest are the opponent\'s';

  @override
  String get tutBonLuckBody =>
      'The rest of your pawns come in your opponent\'s color. If you\'re lucky enough, you could play almost the whole game with the opponent\'s pawns.';

  @override
  String get tutBonDealTitle => 'Let\'s see what you got';

  @override
  String get tutBonDealBody =>
      'This game the number is 4: 4 of your own pawns (gold) and 2 opponent pawns (bordeaux). Here\'s your hand.';

  @override
  String get tutBonDemowinTitle => 'Win with your own pawn';

  @override
  String get tutBonDemowinBody =>
      'Pick one of your gold pawns and complete the bottom-row trio by placing it on the glowing square.';

  @override
  String get tutBonWarningTitle => 'But one day your pawns run out';

  @override
  String get tutBonWarningBody =>
      'When your gold pawns run out, only the opponent\'s remain in your hand. And placing those… can help your opponent.';

  @override
  String get tutBonDemoloseTitle => 'A forced move';

  @override
  String get tutBonDemoloseBody =>
      'Only opponent pawns are left in your hand and you must place one on an empty square. But look — wherever you place it, you hand your opponent a line.';

  @override
  String get tutBonDoneTitle => 'That\'s Bonanza!';

  @override
  String get tutBonDoneBody =>
      'Bonanza is where luck meets strategy. Sometimes the opponent\'s pawns smile on you, sometimes they bite. Give it a go — is luck on your side?';

  @override
  String tutBonBadgeNumber(String n) {
    return 'Number: $n';
  }

  @override
  String get tutBonRailGold => 'Your gold pawns';

  @override
  String get tutBonRailBord => 'The opponent pawns you have left';

  @override
  String get tutBonHintLose =>
      'Pick a pawn and place it on an empty square — see what happens';

  @override
  String get tutBonHintRedirectEmpty => 'Place it on an empty square';

  @override
  String get tutBonHintOppWin => 'Opponent wins — that\'s Bonanza\'s risk';

  @override
  String get tutBonBtnKnown => 'I know it, continue';

  @override
  String get tutBonBtnCurious => 'I\'m curious';

  @override
  String get tutBonBtnShow => 'Show me';

  @override
  String get tutBonBtnWhy => 'Why?';

  @override
  String get tutBonBtnLearnOriginal => 'Learn Original';

  @override
  String get tutMorphWelcomeTitle => 'Welcome to Morph';

  @override
  String get tutMorphWelcomeBody =>
      'This is the most different place you\'ll reach. Morph bends everything you\'re used to — but don\'t worry, we\'ll work through it together, step by step. Ready when you are.';

  @override
  String get tutMorphOriginalTitle => 'First, the basics';

  @override
  String get tutMorphOriginalBody =>
      'You place and capture pawns just like in Original. If you haven\'t learned that yet, drop by there first.';

  @override
  String get tutMorphMysteryTitle => 'But winning…';

  @override
  String get tutMorphMysteryBody =>
      'In this mode you\'ll need to do something else to win…';

  @override
  String get tutMorphShapesTitle => 'Four pawns, one shape';

  @override
  String get tutMorphShapesBody =>
      'To win you must bring four of your pawns together into a shape: an I, an L, or a Z.';

  @override
  String get tutMorphTwomovesTitle => 'That\'s why you move twice';

  @override
  String get tutMorphTwomovesBody =>
      'Building a four-pawn shape one at a time would be very hard. So in Morph you place two pawns each turn — and you hold two of every value.';

  @override
  String get tutMorphIvTitle => 'Complete the shape — I';

  @override
  String get tutMorphIvBody =>
      'That column is almost ready. Pick a pawn and complete a vertical I by placing it on the glowing square.';

  @override
  String get tutMorphIhTitle => 'Two pawns this time';

  @override
  String get tutMorphIhBody =>
      'Now it\'s the double move. Pick two pawns in turn and place them on the two glowing squares to complete a horizontal I.';

  @override
  String get tutMorphDiagTitle => 'Shapes can be slanted too';

  @override
  String get tutMorphDiagBody =>
      'I, L, and Z don\'t have to stand upright — a diagonal, slanted shape wins just as well.';

  @override
  String get tutMorphZTitle => 'A diagonal Z';

  @override
  String get tutMorphZBody =>
      'Place your pawn on the glowing square and complete a slanted Z.';

  @override
  String get tutMorphMirrorTitle => 'The mirror counts too';

  @override
  String get tutMorphMirrorBody =>
      'A shape\'s mirror image wins just like the shape itself. A flipped L is still an L.';

  @override
  String get tutMorphLTitle => 'A mirrored L';

  @override
  String get tutMorphLBody =>
      'Finally: place on the glowing square and complete a mirrored L.';

  @override
  String get tutMorphDoneTitle => 'That\'s Morph!';

  @override
  String get tutMorphDoneBody =>
      'Now you speak the language of shapes — I, L, Z; straight, slanted, or mirrored. Try it in a real game; build a shape and claim the win.';

  @override
  String get tutMorphHintFirst =>
      'Pick the first pawn and place it on a glowing square';

  @override
  String get tutMorphHintOneMore =>
      'One more — place it on the other glowing square';

  @override
  String get tutMorphHintRedirect => 'Place it on a glowing square';

  @override
  String tutMorphHintWin(String shape) {
    return 'You win! You made a $shape';
  }

  @override
  String get tutMorphBtnHow => 'How so?';

  @override
  String get tutMorphBtnOneMore => 'One last example';
}
