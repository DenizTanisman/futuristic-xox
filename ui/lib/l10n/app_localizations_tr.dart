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
}
