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
  String get settingsSfx => 'Звуковые эффекты';

  @override
  String get settingsSfxVolume => 'Громкость эффектов';

  @override
  String get settingsMusic => 'Музыка';

  @override
  String get settingsMusicVolume => 'Громкость музыки';

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
  String get resultYouWin => 'Вы победили!';

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

  @override
  String get tutBtnNext => 'Дальше';

  @override
  String get tutRailLabel => 'Ваши фишки';

  @override
  String get tutHintSelect => 'Сначала выберите фишку';

  @override
  String get tutHintPlaceNow => 'Теперь коснитесь клетки';

  @override
  String get tutHintEat =>
      'Выберите фишку, затем коснитесь центральной фишки соперника';

  @override
  String get tutHintWinPlace =>
      'Выберите фишку, затем коснитесь светящейся клетки';

  @override
  String get tutHintEatwin =>
      'Выберите фишку больше 5, затем поставьте в центр';

  @override
  String get tutHintSmall => 'Слишком мала — выберите фишку покрупнее';

  @override
  String get tutHintRedirect => 'Поставьте на светящуюся клетку';

  @override
  String get tutHintWin => 'Вы победили!';

  @override
  String get tutOrigWelcomeTitle => 'Добро пожаловать в Futuristic';

  @override
  String get tutOrigWelcomeBody =>
      'Сейчас вы сыграете в крестики-нолики, каких ещё не видели. Не спеша — новые правила откроем вместе, шаг за шагом. Начнём, когда будете готовы.';

  @override
  String get tutOrigNumbersTitle => 'Теперь есть числа';

  @override
  String get tutOrigNumbersBody =>
      'Вы ставите не просто X или O, а ценные числа — и у каждого своя сила. Эта маленькая деталь меняет всё.';

  @override
  String get tutOrigPlaceTitle => 'Поставьте любую фишку';

  @override
  String get tutOrigPlaceBody =>
      'Любую свою фишку можно поставить на пустую клетку. Смотрите — золотая фишка появляется на светящейся клетке.';

  @override
  String get tutOrigDemoplaceTitle => 'Теперь попробуйте';

  @override
  String get tutOrigDemoplaceBody =>
      'Сначала выберите фишку снизу, затем коснитесь пустой клетки, чтобы поставить её.';

  @override
  String get tutOrigCapintroTitle => 'Можно и захватывать';

  @override
  String get tutOrigCapintroBody =>
      'Самое интересное: можно захватить фишку соперника. Смотрите — золотая фишка побольше встаёт на чужую и забирает её.';

  @override
  String get tutOrigCapruleTitle => 'Но есть одно правило';

  @override
  String get tutOrigCapruleBody =>
      'Чтобы захватить фишку, ваша должна быть строго большего значения. Меньшая не возьмёт большую.';

  @override
  String get tutOrigDemoeatTitle => 'Теперь захватите вы';

  @override
  String get tutOrigDemoeatBody =>
      'Попробуйте захватить фишку соперника (3) в центре. Сначала маленькой фишкой — потом достаточно большой.';

  @override
  String get tutOrigWinruleTitle => 'Как победить';

  @override
  String get tutOrigWinruleBody =>
      'Победа всё та же: соберите три свои фишки в ряд — по горизонтали, вертикали или диагонали. Важен ряд, а не значения.';

  @override
  String get tutOrigDemowinTitle => 'Завершите линию';

  @override
  String get tutOrigDemowinBody =>
      'Поставьте фишку на светящуюся пустую клетку и завершите тройку в правом столбце.';

  @override
  String get tutOrigDemoeatwinTitle => 'Захват и победа разом';

  @override
  String get tutOrigDemoeatwinBody =>
      'На этот раз победный ход ещё и захватывает. Выберите фишку, способную взять 5 соперника в центре, поставьте туда и закройте диагональ.';

  @override
  String get tutOrigDoneTitle => 'Вот и весь Original!';

  @override
  String get tutOrigDoneBody =>
      'Теперь вы знаете силу чисел, захват и победу. Попробуйте в настоящей игре — станьте победителем.';

  @override
  String get tutBonWelcomeTitle => 'Добро пожаловать в Bonanza';

  @override
  String get tutBonWelcomeBody =>
      'Здесь в игру вступает удача. За несколько ходов мы вместе раскроем хитрость этого режима — не волнуйся, самое весёлое уже близко.';

  @override
  String get tutBonOriginalTitle => 'Сначала основы';

  @override
  String get tutBonOriginalBody =>
      'Ты ставишь фишки и побеждаешь, выстроив три своих в ряд — как в Original. Если ещё не освоил это, загляни сначала туда.';

  @override
  String get tutBonHookTitle => 'А что, если…';

  @override
  String get tutBonHookBody =>
      'что, если часть фишек соперника окажется у тебя с самого начала? 🙂 Именно это и делает Bonanza.';

  @override
  String get tutBonRandomTitle => 'Всё начинается с числа';

  @override
  String get tutBonRandomBody =>
      'В Bonanza в начале каждой игры выпадает случайное число. Оно решает, сколько собственных фишек будет у тебя на руках.';

  @override
  String get tutBonLuckTitle => 'Остальные — соперника';

  @override
  String get tutBonLuckBody =>
      'Остальные фишки достаются тебе в цвете соперника. Если повезёт — почти всю партию можно сыграть чужими фишками.';

  @override
  String get tutBonDealTitle => 'Посмотрим, что тебе досталось';

  @override
  String get tutBonDealBody =>
      'В этой игре число — 4: четыре твои фишки (золото) и две фишки соперника (бордо). Вот твоя рука.';

  @override
  String get tutBonDemowinTitle => 'Победи своей фишкой';

  @override
  String get tutBonDemowinBody =>
      'Выбери одну из своих золотых фишек и заверши тройку в нижнем ряду, поставив её на светящуюся клетку.';

  @override
  String get tutBonWarningTitle => 'Но однажды фишки кончатся';

  @override
  String get tutBonWarningBody =>
      'Когда твои золотые фишки закончатся, на руках останутся только фишки соперника. А ставить их… может сыграть ему на руку.';

  @override
  String get tutBonDemoloseTitle => 'Вынужденный ход';

  @override
  String get tutBonDemoloseBody =>
      'На руках остались только фишки соперника, и ты обязан поставить одну на пустую клетку. Но смотри — куда бы ты ни поставил, ты даришь сопернику линию.';

  @override
  String get tutBonDoneTitle => 'Вот и весь Bonanza!';

  @override
  String get tutBonDoneBody =>
      'Bonanza — это место, где удача встречается со стратегией. Иногда фишки соперника тебе улыбаются, иногда кусают. Попробуй — удача на твоей стороне?';

  @override
  String tutBonBadgeNumber(String n) {
    return 'Число: $n';
  }

  @override
  String get tutBonRailGold => 'Твои золотые фишки';

  @override
  String get tutBonRailBord => 'Оставшиеся фишки соперника';

  @override
  String get tutBonHintLose =>
      'Выбери фишку и поставь её на пустую клетку — посмотри, что будет';

  @override
  String get tutBonHintRedirectEmpty => 'Поставь на пустую клетку';

  @override
  String get tutBonHintOppWin => 'Соперник побеждает — таков риск Bonanza';

  @override
  String get tutBonBtnKnown => 'Знаю, дальше';

  @override
  String get tutBonBtnCurious => 'Мне интересно';

  @override
  String get tutBonBtnShow => 'Покажи мне';

  @override
  String get tutBonBtnWhy => 'Почему?';

  @override
  String get tutBonBtnLearnOriginal => 'Изучить Original';

  @override
  String get tutMorphWelcomeTitle => 'Добро пожаловать в Morph';

  @override
  String get tutMorphWelcomeBody =>
      'Это самое необычное, до чего ты доберёшься. Morph слегка выворачивает всё привычное — но не волнуйся, мы разберёмся вместе, шаг за шагом. Готов — начинаем.';

  @override
  String get tutMorphOriginalTitle => 'Сначала основы';

  @override
  String get tutMorphOriginalBody =>
      'Ты ставишь и захватываешь фишки так же, как в Original. Если ещё не освоил это, загляни сначала туда.';

  @override
  String get tutMorphMysteryTitle => 'Но победа…';

  @override
  String get tutMorphMysteryBody =>
      'В этом режиме, чтобы победить, тебе нужно сделать кое-что другое…';

  @override
  String get tutMorphShapesTitle => 'Четыре фишки, одна фигура';

  @override
  String get tutMorphShapesBody =>
      'Чтобы победить, нужно собрать четыре свои фишки в фигуру: I, L или Z.';

  @override
  String get tutMorphTwomovesTitle => 'Поэтому ты ходишь дважды';

  @override
  String get tutMorphTwomovesBody =>
      'Строить фигуру из четырёх фишек по одной было бы очень трудно. Поэтому в Morph за ход ты ставишь две фишки — и каждой ценности у тебя по две.';

  @override
  String get tutMorphIvTitle => 'Заверши фигуру — I';

  @override
  String get tutMorphIvBody =>
      'Этот столбец почти готов. Выбери фишку и заверши вертикальную I, поставив её на светящуюся клетку.';

  @override
  String get tutMorphIhTitle => 'На этот раз две фишки';

  @override
  String get tutMorphIhBody =>
      'Теперь двойной ход. Выбери две фишки по очереди и поставь их на две светящиеся клетки, чтобы завершить горизонтальную I.';

  @override
  String get tutMorphDiagTitle => 'Фигуры бывают и наклонными';

  @override
  String get tutMorphDiagBody =>
      'I, L и Z не обязаны стоять прямо — диагональная, наклонная фигура побеждает так же.';

  @override
  String get tutMorphZTitle => 'Диагональная Z';

  @override
  String get tutMorphZBody =>
      'Поставь фишку на светящуюся клетку и заверши наклонную Z.';

  @override
  String get tutMorphMirrorTitle => 'Зеркало тоже считается';

  @override
  String get tutMorphMirrorBody =>
      'Зеркальное отражение фигуры побеждает так же, как и сама фигура. Перевёрнутая L — это всё ещё L.';

  @override
  String get tutMorphLTitle => 'Зеркальная L';

  @override
  String get tutMorphLBody =>
      'Напоследок: поставь на светящуюся клетку и заверши зеркальную L.';

  @override
  String get tutMorphDoneTitle => 'Вот и весь Morph!';

  @override
  String get tutMorphDoneBody =>
      'Теперь ты владеешь языком фигур — I, L, Z; прямых, наклонных или зеркальных. Попробуй в настоящей игре; собери фигуру и добудь победу.';

  @override
  String get tutMorphHintFirst =>
      'Выбери первую фишку и поставь её на светящуюся клетку';

  @override
  String get tutMorphHintOneMore =>
      'Ещё одна — поставь на другую светящуюся клетку';

  @override
  String get tutMorphHintRedirect => 'Поставь на светящуюся клетку';

  @override
  String tutMorphHintWin(String shape) {
    return 'Победа! Ты собрал $shape';
  }

  @override
  String get tutMorphBtnHow => 'Это как?';

  @override
  String get tutMorphBtnOneMore => 'Последний пример';
}
