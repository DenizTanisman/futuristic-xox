// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get menuLabel => 'Меню';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navAbout => 'О приложении';

  @override
  String get navIssue => 'Сообщить о проблеме';

  @override
  String get homeHint => 'Коснитесь стороны, чтобы играть';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String get aboutBody =>
      'Futuristic XOX начался с простого вопроса: что если у скромных фишек крестиков-ноликов появится вес? Здесь они несут числа и могут захватывать друг друга; классическая игра X/O живёт как отдельный режим; а пара поворотов — случайные руки и сбор фигур — делают каждую партию свежей. Сделано с заботой о плавности и премиальном ощущении. Приятной игры — и пусть победит лучший тактик.';

  @override
  String get issueTitle => 'Сообщить о проблеме';

  @override
  String get issueFaq => 'ЧаВо';

  @override
  String get issueFaqItem => 'Вопрос';

  @override
  String get issueFaqSoon => 'Ответ скоро появится.';

  @override
  String get issueContact => 'Контакт';

  @override
  String get issueContactNote =>
      'Нашли ошибку или есть предложение? Будем рады услышать.';

  @override
  String get tapToPlay => 'Коснитесь, чтобы играть';

  @override
  String get classicTagline => 'Серебро × Золото';

  @override
  String get futuristicTagline => 'Захват · Господство';

  @override
  String get modeClassic => 'Классика';

  @override
  String get modeFuturistic => 'Футуристик';

  @override
  String get chooseMode => 'Выберите режим';

  @override
  String get modeOriginal => 'Original';

  @override
  String get modeOriginalDesc =>
      'Классический ход с ценными фишками и захватом';

  @override
  String get modeBonanza => 'Bonanza';

  @override
  String get modeBonanzaDesc => 'Случайные стартовые руки — как повезёт';

  @override
  String get modeMorph => 'Morph';

  @override
  String get modeMorphDesc => 'Соберите фигуру из 4 клеток, чтобы победить';

  @override
  String get difficultyLabel => 'Сложность';

  @override
  String get gridLabel => 'Поле';

  @override
  String get difficultyEasy => 'Лёгкий';

  @override
  String get difficultyMedium => 'Средний';

  @override
  String get difficultyHard => 'Сложный';

  @override
  String get startButton => 'Старт';

  @override
  String get offlineMpTitle => 'Офлайн на двоих';

  @override
  String get offlineMpOn => 'Два игрока · одно устройство';

  @override
  String get offlineMpOff => 'Игра против компьютера';

  @override
  String get playerYou => 'Вы';

  @override
  String get playerComputer => 'Компьютер';

  @override
  String get player1 => 'Игрок 1';

  @override
  String get player2 => 'Игрок 2';

  @override
  String get turnSuffix => 'ход';

  @override
  String moveOfTwo(int n) {
    return 'ход $n из 2';
  }

  @override
  String get captureMsg => 'Захват!';

  @override
  String get noSecondMove => 'Второго хода нет — ход переходит';

  @override
  String get selectPawnFirst => 'Сначала выберите фишку';

  @override
  String resultWins(String name) {
    return '$name победил!';
  }

  @override
  String get resultDraw => 'Ничья';

  @override
  String get target => 'Цель';

  @override
  String get anyRotation => 'любой поворот';

  @override
  String get restart => 'Заново';

  @override
  String get menuButton => 'Меню';

  @override
  String get playAgain => 'Играть снова';

  @override
  String get yourHand => 'ВАША РУКА';

  @override
  String bonanzaHandLine(int own, int total, int opp) {
    return '$own из ваших $total фишек вашего цвета\n($opp — цвета соперника)';
  }

  @override
  String get tutSkip => 'Пропустить';

  @override
  String get tutHintGlow => 'Коснитесь светящейся клетки';

  @override
  String get tutHintWrong => 'Не туда — поставьте на светящуюся клетку';

  @override
  String get tutHintGreat => 'Отлично!';

  @override
  String get tutCapH => 'Горизонталь';

  @override
  String get tutCapV => 'Вертикаль';

  @override
  String get tutCapD => 'Диагональ';

  @override
  String get tutBtnStart => 'Начнём';

  @override
  String get tutBtnOk => 'Понятно';

  @override
  String get tutBtnTry => 'Давайте попробуем';

  @override
  String get tutBtnFinish => 'Готово';

  @override
  String get tutClassicWelcomeTitle => 'Добро пожаловать';

  @override
  String get tutClassicWelcomeBody =>
      'Рады видеть вас здесь. Сейчас вместе разберём эту доску — не спеша, шаг за шагом, бок о бок. Начнём, когда будете готовы.';

  @override
  String get tutClassicTurnTitle => 'Ваш ход — вы начинаете';

  @override
  String get tutClassicTurnBody =>
      'Когда ваш ход, вы ставите X на доску. Смотрите — X появляется на светящейся клетке.';

  @override
  String get tutClassicDemo1Title => 'Теперь попробуйте сами';

  @override
  String get tutClassicDemo1Body =>
      'Коснитесь светящейся клетки и поставьте свой первый X. (Любая пустая клетка тоже подойдёт.)';

  @override
  String get tutClassicDemo1Hint => 'Коснитесь светящейся клетки';

  @override
  String get tutClassicWinruleTitle => 'Единственный секрет победы';

  @override
  String get tutClassicWinruleBody =>
      'Соберите три X в ряд — по горизонтали, вертикали или диагонали, неважно. Завершите линию и победите.';

  @override
  String get tutClassicDemo2aTitle => '1 / 3 — Горизонталь';

  @override
  String get tutClassicDemo2aBody =>
      'Два X уже в ряд. Завершите светящуюся клетку и закройте горизонтальную линию.';

  @override
  String get tutClassicDemo2bTitle => '2 / 3 — Вертикаль';

  @override
  String get tutClassicDemo2bBody =>
      'На этот раз завершаем столбец. Поставьте X на светящуюся клетку.';

  @override
  String get tutClassicDemo2cTitle => '3 / 3 — Диагональ';

  @override
  String get tutClassicDemo2cBody =>
      'И наконец, диагональ. Поставьте X на светящуюся центральную клетку и завершите тройку.';

  @override
  String get tutClassicDoneTitle => 'Вот и всё!';

  @override
  String get tutClassicDoneBody =>
      'Теперь доска Classic полностью ваша. Переходите к настоящей игре в любой момент — удачи, и пусть победа будет за вами.';

  @override
  String get tutLaunch => 'Как играть';

  @override
  String get navTutorials => 'Обучение';

  @override
  String get tutSoon => 'Скоро';
}
