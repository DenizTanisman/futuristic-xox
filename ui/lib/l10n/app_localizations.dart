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
