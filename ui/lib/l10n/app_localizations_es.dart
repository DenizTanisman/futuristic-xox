// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get menuLabel => 'Menú';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navAbout => 'Acerca de';

  @override
  String get navIssue => 'Reportar problema';

  @override
  String get homeHint => 'Toca un lado para jugar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutBody =>
      'Futuristic XOX nació de una pregunta simple: ¿y si las humildes fichas del tres en raya tuvieran peso? Aquí llevan números y pueden capturarse entre sí; el clásico X/O sigue vivo como su propio modo; y unos giros — manos aleatorias, completar figuras — mantienen cada partida fresca. Hecho con cariño para una sensación fluida y premium. Diviértete, y que gane el mejor estratega.';

  @override
  String get issueTitle => 'Reportar problema';

  @override
  String get issueFaq => 'Preguntas frecuentes';

  @override
  String get issueFaqItem => 'Pregunta';

  @override
  String get issueFaqSoon => 'La respuesta llegará pronto.';

  @override
  String get issueContact => 'Contacto';

  @override
  String get issueContactNote =>
      '¿Encontraste un error o tienes una sugerencia? Nos encantaría saberlo.';

  @override
  String get tapToPlay => 'Toca para jugar';

  @override
  String get classicTagline => 'Plata × Oro';

  @override
  String get futuristicTagline => 'Captura · Conquista';

  @override
  String get modeClassic => 'Clásico';

  @override
  String get modeFuturistic => 'Futurista';

  @override
  String get chooseMode => 'Elige un modo';

  @override
  String get modeOriginal => 'Original';

  @override
  String get modeOriginalDesc => 'Flujo clásico con fichas con valor y captura';

  @override
  String get modeBonanza => 'Bonanza';

  @override
  String get modeBonanzaDesc =>
      'Manos iniciales aleatorias — cuestión de suerte';

  @override
  String get modeMorph => 'Morph';

  @override
  String get modeMorphDesc => 'Completa una figura de 4 celdas para ganar';

  @override
  String get difficultyLabel => 'Dificultad';

  @override
  String get gridLabel => 'Tablero';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Media';

  @override
  String get difficultyHard => 'Difícil';

  @override
  String get startButton => 'Jugar';

  @override
  String get offlineMpTitle => 'Multijugador local';

  @override
  String get offlineMpOn => 'Dos jugadores · mismo dispositivo';

  @override
  String get offlineMpOff => 'Juega contra la máquina';

  @override
  String get playerYou => 'Tú';

  @override
  String get playerComputer => 'Máquina';

  @override
  String get player1 => 'Jugador 1';

  @override
  String get player2 => 'Jugador 2';

  @override
  String get turnSuffix => 'turno';

  @override
  String moveOfTwo(int n) {
    return 'movimiento $n de 2';
  }

  @override
  String get captureMsg => '¡Captura!';

  @override
  String get noSecondMove => 'No hay segundo movimiento — pasa el turno';

  @override
  String get selectPawnFirst => 'Primero elige una ficha';

  @override
  String resultWins(String name) {
    return '¡$name gana!';
  }

  @override
  String get resultDraw => 'Empate';

  @override
  String get target => 'Objetivo';

  @override
  String get anyRotation => 'cualquier rotación';

  @override
  String get restart => 'Reiniciar';

  @override
  String get menuButton => 'Menú';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get yourHand => 'TU MANO';

  @override
  String bonanzaHandLine(int own, int total, int opp) {
    return '$own de tus $total fichas son de tu color\n($opp son del rival)';
  }
}
