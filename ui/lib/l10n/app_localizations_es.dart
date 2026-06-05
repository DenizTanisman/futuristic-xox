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
  String get settingsSfx => 'Efectos de sonido';

  @override
  String get settingsSfxVolume => 'Volumen de efectos';

  @override
  String get settingsMusic => 'Música';

  @override
  String get settingsMusicVolume => 'Volumen de música';

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
  String get resultYouWin => '¡Ganaste!';

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

  @override
  String get tutSkip => 'Saltar';

  @override
  String get tutHintGlow => 'Toca la casilla que brilla';

  @override
  String get tutHintWrong => 'Ahí no — colócala en la casilla que brilla';

  @override
  String get tutHintGreat => '¡Bien!';

  @override
  String get tutCapH => 'Horizontal';

  @override
  String get tutCapV => 'Vertical';

  @override
  String get tutCapD => 'Diagonal';

  @override
  String get tutBtnStart => 'Empecemos';

  @override
  String get tutBtnOk => 'Entendido';

  @override
  String get tutBtnTry => 'Vamos a probar';

  @override
  String get tutBtnFinish => 'Terminar';

  @override
  String get tutClassicWelcomeTitle => 'Bienvenido';

  @override
  String get tutClassicWelcomeBody =>
      'Qué bueno tenerte aquí. Aprenderemos este tablero juntos en un momento — sin prisa, paso a paso, hombro con hombro. Cuando estés listo, empezamos.';

  @override
  String get tutClassicTurnTitle => 'Tu turno para empezar';

  @override
  String get tutClassicTurnBody =>
      'Cuando es tu turno colocas una X en el tablero. Mira — una X cae en la casilla que brilla.';

  @override
  String get tutClassicDemo1Title => 'Ahora prueba tú';

  @override
  String get tutClassicDemo1Body =>
      'Toca la casilla que brilla y coloca tu primera X. (Cualquier casilla vacía también vale.)';

  @override
  String get tutClassicDemo1Hint => 'Toca la casilla que brilla';

  @override
  String get tutClassicWinruleTitle => 'El único secreto para ganar';

  @override
  String get tutClassicWinruleBody =>
      'Alinea tres X — horizontal, vertical o diagonal, da igual. Completa la línea y ganas.';

  @override
  String get tutClassicDemo2aTitle => '1 / 3 — Horizontal';

  @override
  String get tutClassicDemo2aBody =>
      'Dos X ya están alineadas. Completa la casilla que brilla y cierra la línea horizontal.';

  @override
  String get tutClassicDemo2bTitle => '2 / 3 — Vertical';

  @override
  String get tutClassicDemo2bBody =>
      'Esta vez completamos la columna. Coloca una X en la casilla que brilla.';

  @override
  String get tutClassicDemo2cTitle => '3 / 3 — Diagonal';

  @override
  String get tutClassicDemo2cBody =>
      'Por último, la diagonal. Coloca una X en la casilla central que brilla y completa el trío.';

  @override
  String get tutClassicDoneTitle => '¡Eso es todo!';

  @override
  String get tutClassicDoneBody =>
      'El tablero Classic ya es todo tuyo. Salta a una partida real cuando quieras — suerte, y que seas tú quien gane.';

  @override
  String get tutLaunch => 'Cómo jugar';

  @override
  String get navTutorials => 'Tutoriales';

  @override
  String get tutSoon => 'Próximamente';

  @override
  String get tutBtnNext => 'Continuar';

  @override
  String get tutRailLabel => 'Tus fichas';

  @override
  String get tutHintSelect => 'Primero elige una ficha';

  @override
  String get tutHintPlaceNow => 'Ahora toca una casilla';

  @override
  String get tutHintEat => 'Elige una ficha y toca la ficha rival del centro';

  @override
  String get tutHintWinPlace => 'Elige una ficha y toca la casilla que brilla';

  @override
  String get tutHintEatwin =>
      'Elige una ficha mayor que 5 y colócala en el centro';

  @override
  String get tutHintSmall => 'Demasiado pequeña — elige una ficha mayor';

  @override
  String get tutHintRedirect => 'Colócala en la casilla que brilla';

  @override
  String get tutHintWin => '¡Ganaste!';

  @override
  String get tutOrigWelcomeTitle => 'Bienvenido a Futuristic';

  @override
  String get tutOrigWelcomeBody =>
      'Vas a jugar al tres en raya como nunca lo has visto. Sin prisa — descubriremos las nuevas reglas juntos, paso a paso. Cuando estés listo, empezamos.';

  @override
  String get tutOrigNumbersTitle => 'Ahora hay números';

  @override
  String get tutOrigNumbersBody =>
      'Ya no colocas solo X u O. En su lugar colocas números con valor — y cada uno tiene un poder. Ese pequeño cambio lo cambia todo.';

  @override
  String get tutOrigPlaceTitle => 'Coloca la ficha que quieras';

  @override
  String get tutOrigPlaceBody =>
      'Puedes soltar cualquiera de tus fichas en una casilla vacía. Mira — una ficha dorada cae en la casilla que brilla.';

  @override
  String get tutOrigDemoplaceTitle => 'Ahora prueba tú';

  @override
  String get tutOrigDemoplaceBody =>
      'Primero elige una ficha abajo, luego toca una casilla vacía para colocarla.';

  @override
  String get tutOrigCapintroTitle => 'También puedes capturar';

  @override
  String get tutOrigCapintroBody =>
      'Lo divertido: puedes capturar la ficha del rival. Mira — una ficha dorada mayor cae sobre la suya y se la lleva.';

  @override
  String get tutOrigCapruleTitle => 'Pero hay una regla';

  @override
  String get tutOrigCapruleBody =>
      'Para capturar una ficha, la tuya debe tener un valor estrictamente mayor. Una ficha menor no puede tomar una mayor.';

  @override
  String get tutOrigDemoeatTitle => 'Ahora captura tú';

  @override
  String get tutOrigDemoeatBody =>
      'Intenta capturar la ficha rival (3) del centro. Primero con una ficha pequeña — luego con una lo bastante grande.';

  @override
  String get tutOrigWinruleTitle => 'Cómo ganas';

  @override
  String get tutOrigWinruleBody =>
      'Ganar sigue siendo familiar: alinea tres fichas tuyas — horizontal, vertical o diagonal. Importa la línea, no los valores.';

  @override
  String get tutOrigDemowinTitle => 'Completa la línea';

  @override
  String get tutOrigDemowinBody =>
      'Coloca una ficha en la casilla vacía que brilla y completa el trío de la columna derecha.';

  @override
  String get tutOrigDemoeatwinTitle => 'Captura y gana a la vez';

  @override
  String get tutOrigDemoeatwinBody =>
      'Esta vez tu jugada ganadora también captura. Elige una ficha capaz de tomar el 5 del rival en el centro, colócala ahí y cierra la diagonal.';

  @override
  String get tutOrigDoneTitle => '¡Eso es Original!';

  @override
  String get tutOrigDoneBody =>
      'Ya conoces el poder de los números, la captura y la victoria. Pruébalo en una partida real — sé tú quien gane.';

  @override
  String get tutBonWelcomeTitle => 'Bienvenido a Bonanza';

  @override
  String get tutBonWelcomeBody =>
      'Aquí es donde la suerte entra en juego. Descubriremos juntos el giro de este modo en unos turnos — tranquilo, la parte divertida está cerca.';

  @override
  String get tutBonOriginalTitle => 'Primero, lo básico';

  @override
  String get tutBonOriginalBody =>
      'Colocas peones y ganas alineando tres de los tuyos — igual que en Original. Si aún no lo has aprendido, pásate antes por allí.';

  @override
  String get tutBonHookTitle => '¿Y si…';

  @override
  String get tutBonHookBody =>
      'y si tuvieras algunos peones de tu rival desde el principio? 🙂 Eso es justo lo que hace Bonanza.';

  @override
  String get tutBonRandomTitle => 'Todo empieza con un número';

  @override
  String get tutBonRandomBody =>
      'En Bonanza se sortea un número al inicio de cada partida. Ese número decide cuántos peones propios tendrás en la mano.';

  @override
  String get tutBonLuckTitle => 'El resto son del rival';

  @override
  String get tutBonLuckBody =>
      'El resto de tus peones vienen del color del rival. Si tienes suerte — podrías jugar casi toda la partida con peones del rival.';

  @override
  String get tutBonDealTitle => 'Veamos qué te tocó';

  @override
  String get tutBonDealBody =>
      'En esta partida el número es 4: 4 peones propios (oro) y 2 peones del rival (burdeos). Aquí tienes tu mano.';

  @override
  String get tutBonDemowinTitle => 'Gana con tu propio peón';

  @override
  String get tutBonDemowinBody =>
      'Elige uno de tus peones de oro y completa el trío de la fila inferior colocándolo en la casilla brillante.';

  @override
  String get tutBonWarningTitle => 'Pero un día se acaban tus peones';

  @override
  String get tutBonWarningBody =>
      'Cuando se acaben tus peones de oro, solo quedarán los del rival en tu mano. Y colocarlos… puede ayudar a tu rival.';

  @override
  String get tutBonDemoloseTitle => 'Una jugada forzada';

  @override
  String get tutBonDemoloseBody =>
      'Solo quedan peones del rival en tu mano y debes colocar uno en una casilla vacía. Pero mira — dondequiera que lo pongas, le regalas una línea a tu rival.';

  @override
  String get tutBonDoneTitle => '¡Eso es Bonanza!';

  @override
  String get tutBonDoneBody =>
      'Bonanza es donde la suerte se encuentra con la estrategia. A veces los peones del rival te sonríen, a veces te muerden. Inténtalo — ¿está la suerte de tu lado?';

  @override
  String tutBonBadgeNumber(String n) {
    return 'Número: $n';
  }

  @override
  String get tutBonRailGold => 'Tus peones de oro';

  @override
  String get tutBonRailBord => 'Los peones del rival que te quedan';

  @override
  String get tutBonHintLose =>
      'Elige un peón y colócalo en una casilla vacía — mira qué pasa';

  @override
  String get tutBonHintRedirectEmpty => 'Colócalo en una casilla vacía';

  @override
  String get tutBonHintOppWin => 'Gana el rival — ese es el riesgo de Bonanza';

  @override
  String get tutBonBtnKnown => 'Lo sé, continuar';

  @override
  String get tutBonBtnCurious => 'Tengo curiosidad';

  @override
  String get tutBonBtnShow => 'Muéstrame';

  @override
  String get tutBonBtnWhy => '¿Por qué?';

  @override
  String get tutBonBtnLearnOriginal => 'Aprender Original';

  @override
  String get tutMorphWelcomeTitle => 'Bienvenido a Morph';

  @override
  String get tutMorphWelcomeBody =>
      'Este es el lugar más diferente al que llegarás. Morph tuerce todo lo que conoces — pero tranquilo, lo resolveremos juntos, paso a paso. Cuando estés listo, empezamos.';

  @override
  String get tutMorphOriginalTitle => 'Primero, lo básico';

  @override
  String get tutMorphOriginalBody =>
      'Colocas y capturas peones igual que en Original. Si aún no lo has aprendido, pásate antes por allí.';

  @override
  String get tutMorphMysteryTitle => 'Pero ganar…';

  @override
  String get tutMorphMysteryBody =>
      'En este modo tendrás que hacer otra cosa para ganar…';

  @override
  String get tutMorphShapesTitle => 'Cuatro peones, una forma';

  @override
  String get tutMorphShapesBody =>
      'Para ganar debes reunir cuatro de tus peones en una forma: una I, una L o una Z.';

  @override
  String get tutMorphTwomovesTitle => 'Por eso mueves dos veces';

  @override
  String get tutMorphTwomovesBody =>
      'Construir una forma de cuatro peones de uno en uno sería muy difícil. Así que en Morph colocas dos peones por turno — y tienes dos de cada valor.';

  @override
  String get tutMorphIvTitle => 'Completa la forma — I';

  @override
  String get tutMorphIvBody =>
      'Esa columna casi está lista. Elige un peón y completa una I vertical colocándolo en la casilla brillante.';

  @override
  String get tutMorphIhTitle => 'Dos peones esta vez';

  @override
  String get tutMorphIhBody =>
      'Ahora es el movimiento doble. Elige dos peones por turno y colócalos en las dos casillas brillantes para completar una I horizontal.';

  @override
  String get tutMorphDiagTitle => 'Las formas también pueden inclinarse';

  @override
  String get tutMorphDiagBody =>
      'La I, la L y la Z no tienen que estar rectas — una forma diagonal, inclinada, gana igual.';

  @override
  String get tutMorphZTitle => 'Una Z diagonal';

  @override
  String get tutMorphZBody =>
      'Coloca tu peón en la casilla brillante y completa una Z inclinada.';

  @override
  String get tutMorphMirrorTitle => 'El espejo también cuenta';

  @override
  String get tutMorphMirrorBody =>
      'La imagen reflejada de una forma gana igual que la forma misma. Una L volteada sigue siendo una L.';

  @override
  String get tutMorphLTitle => 'Una L reflejada';

  @override
  String get tutMorphLBody =>
      'Por último: coloca en la casilla brillante y completa una L reflejada.';

  @override
  String get tutMorphDoneTitle => '¡Eso es Morph!';

  @override
  String get tutMorphDoneBody =>
      'Ya hablas el idioma de las formas — I, L, Z; rectas, inclinadas o reflejadas. Pruébalo en una partida real; construye una forma y reclama la victoria.';

  @override
  String get tutMorphHintFirst =>
      'Elige el primer peón y colócalo en una casilla brillante';

  @override
  String get tutMorphHintOneMore =>
      'Uno más — colócalo en la otra casilla brillante';

  @override
  String get tutMorphHintRedirect => 'Colócalo en una casilla brillante';

  @override
  String tutMorphHintWin(String shape) {
    return '¡Ganaste! Hiciste una $shape';
  }

  @override
  String get tutMorphBtnHow => '¿Cómo así?';

  @override
  String get tutMorphBtnOneMore => 'Un último ejemplo';
}
