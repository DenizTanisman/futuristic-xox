import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @menuLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuLabel;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @navIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get navIssue;

  /// No description provided for @homeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a side to play'**
  String get homeHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Futuristic XOX began as a simple question: what if the humble tic-tac-toe pawns had weight? Here they carry numbers and can capture one another, classic X/O play lives on as its own mode, and a few twists — randomized hands, shape-completion — keep every match fresh. Built with care for a smooth, premium feel. Have fun, and may the better tactician win.'**
  String get aboutBody;

  /// No description provided for @issueTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueTitle;

  /// No description provided for @issueFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get issueFaq;

  /// No description provided for @issueFaqItem.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get issueFaqItem;

  /// No description provided for @issueFaqSoon.
  ///
  /// In en, this message translates to:
  /// **'The answer to this one is coming soon.'**
  String get issueFaqSoon;

  /// No description provided for @issueContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get issueContact;

  /// No description provided for @issueContactNote.
  ///
  /// In en, this message translates to:
  /// **'Found a bug or have a suggestion? We\'d love to hear from you.'**
  String get issueContactNote;

  /// No description provided for @tapToPlay.
  ///
  /// In en, this message translates to:
  /// **'Tap to play'**
  String get tapToPlay;

  /// No description provided for @classicTagline.
  ///
  /// In en, this message translates to:
  /// **'Silver × Gold'**
  String get classicTagline;

  /// No description provided for @futuristicTagline.
  ///
  /// In en, this message translates to:
  /// **'Capture · Conquer'**
  String get futuristicTagline;

  /// No description provided for @modeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get modeClassic;

  /// No description provided for @modeFuturistic.
  ///
  /// In en, this message translates to:
  /// **'Futuristic'**
  String get modeFuturistic;

  /// No description provided for @chooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get chooseMode;

  /// No description provided for @modeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get modeOriginal;

  /// No description provided for @modeOriginalDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic flow with valued pawns & capture'**
  String get modeOriginalDesc;

  /// No description provided for @modeBonanza.
  ///
  /// In en, this message translates to:
  /// **'Bonanza'**
  String get modeBonanza;

  /// No description provided for @modeBonanzaDesc.
  ///
  /// In en, this message translates to:
  /// **'Randomized starting hands — luck of the draw'**
  String get modeBonanzaDesc;

  /// No description provided for @modeMorph.
  ///
  /// In en, this message translates to:
  /// **'Morph'**
  String get modeMorph;

  /// No description provided for @modeMorphDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a 4-cell shape to win'**
  String get modeMorphDesc;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @gridLabel.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridLabel;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @offlineMpTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Multiplayer'**
  String get offlineMpTitle;

  /// No description provided for @offlineMpOn.
  ///
  /// In en, this message translates to:
  /// **'Two players · same device'**
  String get offlineMpOn;

  /// No description provided for @offlineMpOff.
  ///
  /// In en, this message translates to:
  /// **'Play vs computer'**
  String get offlineMpOff;

  /// No description provided for @playerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get playerYou;

  /// No description provided for @playerComputer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get playerComputer;

  /// No description provided for @player1.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get player1;

  /// No description provided for @player2.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get player2;

  /// No description provided for @turnSuffix.
  ///
  /// In en, this message translates to:
  /// **'turn'**
  String get turnSuffix;

  /// No description provided for @moveOfTwo.
  ///
  /// In en, this message translates to:
  /// **'move {n} of 2'**
  String moveOfTwo(int n);

  /// No description provided for @captureMsg.
  ///
  /// In en, this message translates to:
  /// **'Capture!'**
  String get captureMsg;

  /// No description provided for @noSecondMove.
  ///
  /// In en, this message translates to:
  /// **'No second move available — turn passes'**
  String get noSecondMove;

  /// No description provided for @selectPawnFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a pawn first'**
  String get selectPawnFirst;

  /// No description provided for @resultWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins!'**
  String resultWins(String name);

  /// No description provided for @resultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get resultDraw;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @anyRotation.
  ///
  /// In en, this message translates to:
  /// **'any rotation'**
  String get anyRotation;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @menuButton.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuButton;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @yourHand.
  ///
  /// In en, this message translates to:
  /// **'YOUR HAND'**
  String get yourHand;

  /// No description provided for @bonanzaHandLine.
  ///
  /// In en, this message translates to:
  /// **'{own} of your {total} pawns are your own colour\n({opp} are your opponent\'s)'**
  String bonanzaHandLine(int own, int total, int opp);

  /// No description provided for @tutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutSkip;

  /// No description provided for @tutHintGlow.
  ///
  /// In en, this message translates to:
  /// **'Tap the glowing square'**
  String get tutHintGlow;

  /// No description provided for @tutHintWrong.
  ///
  /// In en, this message translates to:
  /// **'Not there — place it on the glowing square'**
  String get tutHintWrong;

  /// No description provided for @tutHintGreat.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get tutHintGreat;

  /// No description provided for @tutCapH.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get tutCapH;

  /// No description provided for @tutCapV.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get tutCapV;

  /// No description provided for @tutCapD.
  ///
  /// In en, this message translates to:
  /// **'Diagonal'**
  String get tutCapD;

  /// No description provided for @tutBtnStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s begin'**
  String get tutBtnStart;

  /// No description provided for @tutBtnOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tutBtnOk;

  /// No description provided for @tutBtnTry.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try'**
  String get tutBtnTry;

  /// No description provided for @tutBtnFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutBtnFinish;

  /// No description provided for @tutClassicWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get tutClassicWelcomeTitle;

  /// No description provided for @tutClassicWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Good to have you here. We\'ll learn this board together in a moment — no rush, step by step, side by side. Ready when you are.'**
  String get tutClassicWelcomeBody;

  /// No description provided for @tutClassicTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'Your turn to start'**
  String get tutClassicTurnTitle;

  /// No description provided for @tutClassicTurnBody.
  ///
  /// In en, this message translates to:
  /// **'When it\'s your turn you drop an X on the board. Watch — an X lands on the glowing square.'**
  String get tutClassicTurnBody;

  /// No description provided for @tutClassicDemo1Title.
  ///
  /// In en, this message translates to:
  /// **'Now you try'**
  String get tutClassicDemo1Title;

  /// No description provided for @tutClassicDemo1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap the glowing square and place your first X. (Any empty square works too.)'**
  String get tutClassicDemo1Body;

  /// No description provided for @tutClassicDemo1Hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the glowing square'**
  String get tutClassicDemo1Hint;

  /// No description provided for @tutClassicWinruleTitle.
  ///
  /// In en, this message translates to:
  /// **'The one secret to winning'**
  String get tutClassicWinruleTitle;

  /// No description provided for @tutClassicWinruleBody.
  ///
  /// In en, this message translates to:
  /// **'Line up three X\'s — horizontal, vertical, or diagonal, it doesn\'t matter. Complete the line and you win.'**
  String get tutClassicWinruleBody;

  /// No description provided for @tutClassicDemo2aTitle.
  ///
  /// In en, this message translates to:
  /// **'1 / 3 — Horizontal'**
  String get tutClassicDemo2aTitle;

  /// No description provided for @tutClassicDemo2aBody.
  ///
  /// In en, this message translates to:
  /// **'Two X\'s are lined up. Complete the glowing square and close the horizontal line.'**
  String get tutClassicDemo2aBody;

  /// No description provided for @tutClassicDemo2bTitle.
  ///
  /// In en, this message translates to:
  /// **'2 / 3 — Vertical'**
  String get tutClassicDemo2bTitle;

  /// No description provided for @tutClassicDemo2bBody.
  ///
  /// In en, this message translates to:
  /// **'This time we complete the column. Place an X on the glowing square.'**
  String get tutClassicDemo2bBody;

  /// No description provided for @tutClassicDemo2cTitle.
  ///
  /// In en, this message translates to:
  /// **'3 / 3 — Diagonal'**
  String get tutClassicDemo2cTitle;

  /// No description provided for @tutClassicDemo2cBody.
  ///
  /// In en, this message translates to:
  /// **'Finally, the diagonal. Place an X on the glowing center square to complete the trio.'**
  String get tutClassicDemo2cBody;

  /// No description provided for @tutClassicDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'That\'s all it takes!'**
  String get tutClassicDoneTitle;

  /// No description provided for @tutClassicDoneBody.
  ///
  /// In en, this message translates to:
  /// **'The Classic board is all yours now. Jump into a real game whenever you like — good luck, and may you be the one who wins.'**
  String get tutClassicDoneBody;

  /// No description provided for @tutLaunch.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get tutLaunch;

  /// No description provided for @navTutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get navTutorials;

  /// No description provided for @tutSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get tutSoon;

  /// No description provided for @tutBtnNext.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get tutBtnNext;

  /// No description provided for @tutRailLabel.
  ///
  /// In en, this message translates to:
  /// **'Your pawns'**
  String get tutRailLabel;

  /// No description provided for @tutHintSelect.
  ///
  /// In en, this message translates to:
  /// **'Pick a pawn first'**
  String get tutHintSelect;

  /// No description provided for @tutHintPlaceNow.
  ///
  /// In en, this message translates to:
  /// **'Now tap a square'**
  String get tutHintPlaceNow;

  /// No description provided for @tutHintEat.
  ///
  /// In en, this message translates to:
  /// **'Pick a pawn, then tap the center opponent pawn'**
  String get tutHintEat;

  /// No description provided for @tutHintWinPlace.
  ///
  /// In en, this message translates to:
  /// **'Pick a pawn, then tap the glowing square'**
  String get tutHintWinPlace;

  /// No description provided for @tutHintEatwin.
  ///
  /// In en, this message translates to:
  /// **'Pick a pawn bigger than 5, then place it in the center'**
  String get tutHintEatwin;

  /// No description provided for @tutHintSmall.
  ///
  /// In en, this message translates to:
  /// **'Too small — pick a bigger pawn'**
  String get tutHintSmall;

  /// No description provided for @tutHintRedirect.
  ///
  /// In en, this message translates to:
  /// **'Place it on the glowing square'**
  String get tutHintRedirect;

  /// No description provided for @tutHintWin.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get tutHintWin;

  /// No description provided for @tutOrigWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Futuristic'**
  String get tutOrigWelcomeTitle;

  /// No description provided for @tutOrigWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re about to play tic-tac-toe like you\'ve never seen it. No rush — we\'ll discover the new rules together, step by step. Ready when you are.'**
  String get tutOrigWelcomeBody;

  /// No description provided for @tutOrigNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Now there are numbers'**
  String get tutOrigNumbersTitle;

  /// No description provided for @tutOrigNumbersBody.
  ///
  /// In en, this message translates to:
  /// **'You no longer place just X or O. Instead you place valued numbers — and each one carries a power. That small change changes everything.'**
  String get tutOrigNumbersBody;

  /// No description provided for @tutOrigPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Place any pawn you like'**
  String get tutOrigPlaceTitle;

  /// No description provided for @tutOrigPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'You can drop any of your pawns on an empty square. Watch — a gold pawn lands on the glowing square.'**
  String get tutOrigPlaceBody;

  /// No description provided for @tutOrigDemoplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Now you try'**
  String get tutOrigDemoplaceTitle;

  /// No description provided for @tutOrigDemoplaceBody.
  ///
  /// In en, this message translates to:
  /// **'First pick a pawn below, then tap an empty square to place it.'**
  String get tutOrigDemoplaceBody;

  /// No description provided for @tutOrigCapintroTitle.
  ///
  /// In en, this message translates to:
  /// **'You can capture, too'**
  String get tutOrigCapintroTitle;

  /// No description provided for @tutOrigCapintroBody.
  ///
  /// In en, this message translates to:
  /// **'Here\'s the fun part: you can capture your opponent\'s pawn. Watch — a larger gold pawn lands on theirs and takes it.'**
  String get tutOrigCapintroBody;

  /// No description provided for @tutOrigCapruleTitle.
  ///
  /// In en, this message translates to:
  /// **'But there\'s one rule'**
  String get tutOrigCapruleTitle;

  /// No description provided for @tutOrigCapruleBody.
  ///
  /// In en, this message translates to:
  /// **'To capture a pawn, yours must have a strictly greater value. A smaller pawn can\'t take a larger one.'**
  String get tutOrigCapruleBody;

  /// No description provided for @tutOrigDemoeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Now you capture'**
  String get tutOrigDemoeatTitle;

  /// No description provided for @tutOrigDemoeatBody.
  ///
  /// In en, this message translates to:
  /// **'Try to capture the opponent pawn (3) in the center. First with a small pawn — then with one that\'s big enough.'**
  String get tutOrigDemoeatBody;

  /// No description provided for @tutOrigWinruleTitle.
  ///
  /// In en, this message translates to:
  /// **'How you win'**
  String get tutOrigWinruleTitle;

  /// No description provided for @tutOrigWinruleBody.
  ///
  /// In en, this message translates to:
  /// **'Winning is still familiar: line up three of your own pawns — horizontal, vertical, or diagonal. It\'s the line that matters, not the values.'**
  String get tutOrigWinruleBody;

  /// No description provided for @tutOrigDemowinTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the line'**
  String get tutOrigDemowinTitle;

  /// No description provided for @tutOrigDemowinBody.
  ///
  /// In en, this message translates to:
  /// **'Place a pawn on the glowing empty square and complete the right-column trio.'**
  String get tutOrigDemowinBody;

  /// No description provided for @tutOrigDemoeatwinTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture and win at once'**
  String get tutOrigDemoeatwinTitle;

  /// No description provided for @tutOrigDemoeatwinBody.
  ///
  /// In en, this message translates to:
  /// **'This time your winning move also captures. Pick a pawn big enough to take the opponent\'s 5 in the center, place it there, and close the diagonal.'**
  String get tutOrigDemoeatwinBody;

  /// No description provided for @tutOrigDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'That\'s Original!'**
  String get tutOrigDoneTitle;

  /// No description provided for @tutOrigDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Now you know the power of numbers, capturing, and winning. Try it in a real game — be the one who wins.'**
  String get tutOrigDoneBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
