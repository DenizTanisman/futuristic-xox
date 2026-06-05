// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get menuLabel => 'Menü';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navAbout => 'Hakkında';

  @override
  String get navIssue => 'Sorun Bildir';

  @override
  String get homeHint => 'Oynamak için bir tarafa dokun';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get settingsSfx => 'Ses Efektleri';

  @override
  String get settingsSfxVolume => 'Efekt Düzeyi';

  @override
  String get settingsMusic => 'Müzik';

  @override
  String get settingsMusicVolume => 'Müzik Düzeyi';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutBody =>
      'Futuristic XOX basit bir soruyla başladı: ya sıradan XOX taşlarının bir ağırlığı olsaydı? Burada taşlar sayı taşır ve birbirini ele geçirebilir; klasik X/O oyunu kendi modu olarak yaşar; rastgele eller ve şekil tamamlama gibi birkaç sürpriz her maçı taze tutar. Akıcı ve özenli bir his için tasarlandı. İyi eğlenceler — kazanan, daha iyi taktisyen olsun.';

  @override
  String get issueTitle => 'Sorun Bildir';

  @override
  String get issueFaq => 'SSS';

  @override
  String get issueFaqItem => 'Soru';

  @override
  String get issueFaqSoon => 'Bunun cevabı yakında eklenecek.';

  @override
  String get issueContact => 'İletişim';

  @override
  String get issueContactNote =>
      'Bir hata mı buldun ya da önerin mi var? Seni duymak isteriz.';

  @override
  String get tapToPlay => 'Oynamak için dokun';

  @override
  String get classicTagline => 'Gümüş × Altın';

  @override
  String get futuristicTagline => 'Ele geçir · Hükmet';

  @override
  String get modeClassic => 'Klasik';

  @override
  String get modeFuturistic => 'Fütüristik';

  @override
  String get chooseMode => 'Bir mod seç';

  @override
  String get modeOriginal => 'Original';

  @override
  String get modeOriginalDesc => 'Değerli taşlar ve ele geçirmeyle klasik akış';

  @override
  String get modeBonanza => 'Bonanza';

  @override
  String get modeBonanzaDesc => 'Rastgele başlangıç elleri — şansına kalmış';

  @override
  String get modeMorph => 'Morph';

  @override
  String get modeMorphDesc => 'Kazanmak için 4 kareli bir şekli tamamla';

  @override
  String get difficultyLabel => 'Zorluk';

  @override
  String get gridLabel => 'Izgara';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyMedium => 'Orta';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get startButton => 'Başla';

  @override
  String get offlineMpTitle => 'Çevrimdışı Çok Oyunculu';

  @override
  String get offlineMpOn => 'İki oyuncu · aynı cihaz';

  @override
  String get offlineMpOff => 'Bilgisayara karşı oyna';

  @override
  String get playerYou => 'Sen';

  @override
  String get playerComputer => 'Bilgisayar';

  @override
  String get player1 => 'Oyuncu 1';

  @override
  String get player2 => 'Oyuncu 2';

  @override
  String get turnSuffix => 'sırası';

  @override
  String moveOfTwo(int n) {
    return 'hamle $n / 2';
  }

  @override
  String get captureMsg => 'Ele geçirildi!';

  @override
  String get noSecondMove => 'İkinci hamle yok — sıra geçiyor';

  @override
  String get selectPawnFirst => 'Önce bir taş seç';

  @override
  String resultWins(String name) {
    return '$name kazandı!';
  }

  @override
  String get resultYouWin => 'Sen kazandın!';

  @override
  String get resultDraw => 'Berabere';

  @override
  String get target => 'Hedef';

  @override
  String get anyRotation => 'her yön';

  @override
  String get restart => 'Yeniden başlat';

  @override
  String get menuButton => 'Menü';

  @override
  String get playAgain => 'Tekrar oyna';

  @override
  String get yourHand => 'ELİN';

  @override
  String bonanzaHandLine(int own, int total, int opp) {
    return '$total taşının $own tanesi kendi renginde\n($opp tanesi rakibinin)';
  }

  @override
  String get tutSkip => 'Geç';

  @override
  String get tutHintGlow => 'Parlayan kareye dokun';

  @override
  String get tutHintWrong => 'Oraya değil — parlayan kareye koy';

  @override
  String get tutHintGreat => 'Harika!';

  @override
  String get tutCapH => 'Yatay';

  @override
  String get tutCapV => 'Dikey';

  @override
  String get tutCapD => 'Çapraz';

  @override
  String get tutBtnStart => 'Başlayalım';

  @override
  String get tutBtnOk => 'Anladım';

  @override
  String get tutBtnTry => 'Hadi deneyelim';

  @override
  String get tutBtnFinish => 'Bitir';

  @override
  String get tutClassicWelcomeTitle => 'Hoş geldin';

  @override
  String get tutClassicWelcomeBody =>
      'Seni burada görmek güzel. Birazdan bu tahtanın dilini birlikte çözeceğiz — acelesi yok, her şeyi adım adım, omuz omuza ilerleyeceğiz. Hazırsan başlıyoruz.';

  @override
  String get tutClassicTurnTitle => 'Sıra sende başlıyor';

  @override
  String get tutClassicTurnBody =>
      'Sıra sana geldiğinde tahtaya bir X bırakırsın. İzle — parlayan kareye bir X düşüveriyor.';

  @override
  String get tutClassicDemo1Title => 'Şimdi sen dene';

  @override
  String get tutClassicDemo1Body =>
      'Parlayan kareye dokun ve ilk X\'ini koy. (Boş kalan herhangi bir kare de olur.)';

  @override
  String get tutClassicDemo1Hint => 'Parlayan kareye dokun';

  @override
  String get tutClassicWinruleTitle => 'Kazanmanın tek sırrı';

  @override
  String get tutClassicWinruleBody =>
      'Üç X\'i bir hizaya getir — yatay, dikey ya da çapraz, fark etmez. Hattı tamamlayan kazanır.';

  @override
  String get tutClassicDemo2aTitle => '1 / 3 — Yatay';

  @override
  String get tutClassicDemo2aBody =>
      'İki X yan yana hazır. Parlayan kareyi tamamla ve yatay hattı kapat.';

  @override
  String get tutClassicDemo2bTitle => '2 / 3 — Dikey';

  @override
  String get tutClassicDemo2bBody =>
      'Bu kez sütunu tamamlıyoruz. Parlayan kareye X koy.';

  @override
  String get tutClassicDemo2cTitle => '3 / 3 — Çapraz';

  @override
  String get tutClassicDemo2cBody =>
      'Son olarak çapraz hat. Ortadaki parlayan kareye X koyup üçlüyü tamamla.';

  @override
  String get tutClassicDoneTitle => 'İşte bu kadar!';

  @override
  String get tutClassicDoneBody =>
      'Artık Classic tahtası tamamen senin. İstediğin an gerçek bir oyuna geçebilirsin — başarılar, kazanan sen ol.';

  @override
  String get tutLaunch => 'Nasıl oynanır';

  @override
  String get navTutorials => 'Eğitimler';

  @override
  String get tutSoon => 'Yakında';

  @override
  String get tutBtnNext => 'Devam';

  @override
  String get tutRailLabel => 'Senin taşların';

  @override
  String get tutHintSelect => 'Önce bir taş seç';

  @override
  String get tutHintPlaceNow => 'Şimdi bir kareye koy';

  @override
  String get tutHintEat => 'Bir taş seç, sonra ortadaki rakip taşına koy';

  @override
  String get tutHintWinPlace => 'Bir taş seç, sonra parlayan kareye koy';

  @override
  String get tutHintEatwin => '5\'ten büyük bir taş seç, sonra ortaya koy';

  @override
  String get tutHintSmall => 'Bu taş çok küçük — daha büyük bir taş seç';

  @override
  String get tutHintRedirect => 'Parlayan kareye koy';

  @override
  String get tutHintWin => 'Kazandın!';

  @override
  String get tutOrigWelcomeTitle => 'Futuristic\'e hoş geldin';

  @override
  String get tutOrigWelcomeBody =>
      'Burada tic-tac-toe\'yu daha önce hiç görmediğin bir hâliyle oynayacaksın. Acele yok — yeni kuralları birlikte, adım adım keşfedeceğiz. Hazırsan başlıyoruz.';

  @override
  String get tutOrigNumbersTitle => 'Artık sayılar var';

  @override
  String get tutOrigNumbersBody =>
      'Sadece X ya da O koymuyorsun. Onların yerine değerli sayılar koyuyorsun — ve her sayının bir gücü var. Bu küçük fark her şeyi değiştiriyor.';

  @override
  String get tutOrigPlaceTitle => 'İstediğin taşı koy';

  @override
  String get tutOrigPlaceBody =>
      'Boş bir kareye dilediğin taşını bırakabilirsin. İzle — parlayan kareye altın bir taş düşüveriyor.';

  @override
  String get tutOrigDemoplaceTitle => 'Şimdi sen dene';

  @override
  String get tutOrigDemoplaceBody =>
      'Önce alttan bir taş seç, sonra boş bir kareye dokunup koy.';

  @override
  String get tutOrigCapintroTitle => 'Taş da yiyebilirsin';

  @override
  String get tutOrigCapintroBody =>
      'İşin güzel yanı: rakibin taşını yiyebilirsin. İzle — daha büyük bir altın taş, rakibin taşının üstüne gelip onu alıyor.';

  @override
  String get tutOrigCapruleTitle => 'Ama bir şartı var';

  @override
  String get tutOrigCapruleBody =>
      'Bir taşı yiyebilmen için, ondan daha büyük değerde bir taşa sahip olman gerekir. Küçük taş, büyüğü yiyemez.';

  @override
  String get tutOrigDemoeatTitle => 'Hadi sen ye';

  @override
  String get tutOrigDemoeatBody =>
      'Ortadaki rakip taşını (3) yemeyi dene. Önce küçük bir taşla — sonra yeterince büyük olanla.';

  @override
  String get tutOrigWinruleTitle => 'Kazanmanın yolu';

  @override
  String get tutOrigWinruleBody =>
      'Kazanmak hâlâ tanıdık: kendi üç taşını yatay, dikey ya da çapraz bir hizaya getir. Değerleri değil, hizayı önemse.';

  @override
  String get tutOrigDemowinTitle => 'Hattı tamamla';

  @override
  String get tutOrigDemowinBody =>
      'Parlayan boş kareye bir taş koy ve sağ sütundaki üçlüyü tamamla.';

  @override
  String get tutOrigDemoeatwinTitle => 'Hem ye, hem kazan';

  @override
  String get tutOrigDemoeatwinBody =>
      'Bu sefer kazanç hamlen aynı zamanda bir taş yiyecek. Ortadaki rakip 5\'i yiyecek kadar büyük bir taş seç ve oraya koyarak çaprazı kapat.';

  @override
  String get tutOrigDoneTitle => 'İşte Original bu kadar!';

  @override
  String get tutOrigDoneBody =>
      'Artık sayıların gücünü, yemeyi ve kazanmayı biliyorsun. Hadi gerçek bir oyunda dene — kazanan sen ol.';

  @override
  String get tutBonWelcomeTitle => 'Bonanza\'ya hoş geldin';

  @override
  String get tutBonWelcomeBody =>
      'Şansın oyuna karıştığı yer burası. Birlikte birkaç turda bu modun sürprizini çözeceğiz — merak etme, en eğlenceli kısmı çok yakında.';

  @override
  String get tutBonOriginalTitle => 'Önce temel';

  @override
  String get tutBonOriginalBody =>
      'Taşları alana koyup üç taşını bir hizaya getirerek kazanırsın — tıpkı Original\'deki gibi. Henüz öğrenmediysen, önce oraya bir uğra.';

  @override
  String get tutBonHookTitle => 'Peki ya…';

  @override
  String get tutBonHookBody =>
      'Rakibinin bazı taşları en baştan sende olsaydı, nasıl olurdu? 🙂 Bonanza tam da bunu yapıyor.';

  @override
  String get tutBonRandomTitle => 'Her şey bir sayıyla başlar';

  @override
  String get tutBonRandomBody =>
      'Bonanza\'da her oyunun başında rastgele bir sayı seçilir. Bu sayı, kaç tane kendi taşına sahip olacağını belirler.';

  @override
  String get tutBonLuckTitle => 'Gerisi rakipten';

  @override
  String get tutBonLuckBody =>
      'Kalan taşların ise rakibinin renginde olur. Yeterince şanslıysan — neredeyse tüm oyunu rakibin taşlarıyla bile oynayabilirsin.';

  @override
  String get tutBonDealTitle => 'Bakalım sana ne düştü';

  @override
  String get tutBonDealBody =>
      'Bu oyunda sayı 4 çıktı: 4 kendi taşın (altın), 2 de rakip taşın (bordo). İşte elin.';

  @override
  String get tutBonDemowinTitle => 'Kendi taşınla kazan';

  @override
  String get tutBonDemowinBody =>
      'Altın taşlarından birini seç ve parlayan kareye koyarak alt sıradaki üçlüyü tamamla.';

  @override
  String get tutBonWarningTitle => 'Ama bir gün taşların biter';

  @override
  String get tutBonWarningBody =>
      'Kendi altın taşların tükendiğinde elinde yalnızca rakibin taşları kalır. Ve onları koymak… rakibine yarayabilir.';

  @override
  String get tutBonDemoloseTitle => 'Mecburi hamle';

  @override
  String get tutBonDemoloseBody =>
      'Elinde sadece rakip taşları kaldı ve boş bir kareye koymak zorundasın. Ama bak — hangi boş kareye ne koyarsan koy, rakibine bir hat kazandırıyorsun.';

  @override
  String get tutBonDoneTitle => 'İşte Bonanza bu kadar!';

  @override
  String get tutBonDoneBody =>
      'Bonanza, şansla stratejinin buluştuğu yer. Bazen rakibin taşları sana gülümser, bazen başına dert olur. Hadi dene — bakalım şans senden yana mı?';

  @override
  String tutBonBadgeNumber(String n) {
    return 'Sayı: $n';
  }

  @override
  String get tutBonRailGold => 'Senin altın taşların';

  @override
  String get tutBonRailBord => 'Elinde kalan rakip taşları';

  @override
  String get tutBonHintLose => 'Bir taş seç ve boş bir kareye koy — sonucu gör';

  @override
  String get tutBonHintRedirectEmpty => 'Boş bir kareye koy';

  @override
  String get tutBonHintOppWin => 'Rakip kazandı — Bonanza\'nın riski işte bu';

  @override
  String get tutBonBtnKnown => 'Biliyorum, devam';

  @override
  String get tutBonBtnCurious => 'Merak ettim';

  @override
  String get tutBonBtnShow => 'Göster bana';

  @override
  String get tutBonBtnWhy => 'Neden?';

  @override
  String get tutBonBtnLearnOriginal => 'Original\'i öğren';

  @override
  String get tutMorphWelcomeTitle => 'Morph\'a hoş geldin';

  @override
  String get tutMorphWelcomeBody =>
      'Geldiğin en farklı yer burası. Morph, alıştığın her şeyi biraz büküyor — ama merak etme, birlikte adım adım çözeceğiz. Hazırsan başlıyoruz.';

  @override
  String get tutMorphOriginalTitle => 'Önce temel';

  @override
  String get tutMorphOriginalBody =>
      'Taşları alana koymayı ve yemeyi Original\'deki gibi yaparsın. Henüz öğrenmediysen, önce oraya bir uğra.';

  @override
  String get tutMorphMysteryTitle => 'Ama kazanmak…';

  @override
  String get tutMorphMysteryBody =>
      'Bu modda kazanmak için başka şeyler yapman lazım…';

  @override
  String get tutMorphShapesTitle => 'Dört taş, bir şekil';

  @override
  String get tutMorphShapesBody =>
      'Kazanmak için dört taşını bir araya getirip bir şekil oluşturmalısın: I, L ya da Z.';

  @override
  String get tutMorphTwomovesTitle => 'Bu yüzden çift hamle';

  @override
  String get tutMorphTwomovesBody =>
      'Dört taşlık bir şekli tek tek koyarak kurmak çok zor olurdu. O yüzden Morph\'ta her sıranda iki taş birden koyarsın — ve her taştan elinde ikişer tane vardır.';

  @override
  String get tutMorphIvTitle => 'Şekli tamamla — I';

  @override
  String get tutMorphIvBody =>
      'Şu sütun neredeyse hazır. Bir taş seç ve parlayan kareye koyarak dikey bir I tamamla.';

  @override
  String get tutMorphIhTitle => 'Bu kez iki taş';

  @override
  String get tutMorphIhBody =>
      'Sıra çift hamlede. İki taşı sırayla seçip iki parlayan kareye koy ve yatay I\'yı tamamla.';

  @override
  String get tutMorphDiagTitle => 'Şekiller eğik de olur';

  @override
  String get tutMorphDiagBody =>
      'I, L ve Z dik durmak zorunda değil — çapraz, yani eğik olarak da kazandırır.';

  @override
  String get tutMorphZTitle => 'Çapraz bir Z';

  @override
  String get tutMorphZBody =>
      'Parlayan kareye taşını koy ve eğik bir Z şeklini tamamla.';

  @override
  String get tutMorphMirrorTitle => 'Aynalı da geçerli';

  @override
  String get tutMorphMirrorBody =>
      'Bir şeklin aynalanmış hâli de tıpkı kendisi gibi kazandırır. Yani ters dönmüş bir L de bir L\'dir.';

  @override
  String get tutMorphLTitle => 'Aynalanmış bir L';

  @override
  String get tutMorphLBody =>
      'Son olarak: parlayan kareye koy ve aynalanmış bir L tamamla.';

  @override
  String get tutMorphDoneTitle => 'İşte Morph bu kadar!';

  @override
  String get tutMorphDoneBody =>
      'Artık şekillerin dilini biliyorsun — I, L, Z; düz, çapraz ya da aynalı. Hadi gerçek bir oyunda dene; bir şekil kurup zafere ulaş.';

  @override
  String get tutMorphHintFirst => 'İlk taşı seç ve parlayan bir kareye koy';

  @override
  String get tutMorphHintOneMore => 'Bir taş daha — diğer parlayan kareye koy';

  @override
  String get tutMorphHintRedirect => 'Parlayan kareye koy';

  @override
  String tutMorphHintWin(String shape) {
    return 'Kazandın! Bir $shape kurdun';
  }

  @override
  String get tutMorphBtnHow => 'Nasıl yani?';

  @override
  String get tutMorphBtnOneMore => 'Son bir örnek';
}
