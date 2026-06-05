# Store metadata — Futuristic XOX v1.0.0

Draft copy for Google Play and the App Store. English is the default listing; Turkish is provided for a
localized listing. Tune to each store's character limits before upload (Play short description ≤ 80
chars; App Store subtitle ≤ 30 chars; Play full description ≤ 4000 chars).

> Screenshots/feature graphic are produced during the on-device test pass (🛑 needs a device) — see
> `aidlc-docs/release/screenshots/` (placeholder).

---

## App identity

- **Name:** Futuristic XOX
- **Bundle / Application ID:** `com.futuristicxox.futuristicXox` (iOS) · `com.futuristicxox.futuristic_xox` (Android)
- **Category:** Games › Board / Strategy
- **Content rating:** Everyone / 3+ (no violence, no ads, no in-app purchases, no data collection)
- **Price:** Free
- **Languages:** Turkish, English, Russian, Spanish

---

## English

**Title:** Futuristic XOX

**Short description (≤ 80):**
Tic-tac-toe reimagined — valued pawns that capture, plus three futuristic modes.

**Subtitle (App Store, ≤ 30):**
Capture. Build shapes. Win.

**Full description:**
Futuristic XOX takes the game you know and gives it depth. Pawns now carry numbers and can capture
weaker enemy pawns — every square becomes a fight. Classic X/O play is preserved as its own mode for
when you want the original.

Four ways to play:
• Classic — pure 3-in-a-row, on 3×3 or 4×4.
• Original — valued pawns that capture; line up three to win.
• Bonanza — a random hand each game; you might even play with your opponent's colour.
• Morph — place two pawns a turn and build a 4-cell shape (I, L, or Z) in any rotation, mirror, or
  diagonal to win.

Features:
• Three AI difficulties powered by a native search engine — Hard genuinely fights back.
• Smooth, polished 60fps board with a metallic look and a continuous win-line.
• Interactive tutorials for every mode.
• Pass-and-play local multiplayer.
• Four languages, light & dark themes, and sound effects you can tune.
• Fully offline. No ads. No tracking. No accounts.

**Keywords (App Store, ≤ 100 chars, comma-separated):**
tic tac toe,xox,strategy,board game,capture,puzzle,offline,2 player,morph,classic

---

## Türkçe

**Başlık:** Futuristic XOX

**Kısa açıklama (≤ 80):**
Yeniden tasarlanan XOX — değer taşıyan, rakibini yiyen taşlar ve üç fütüristik mod.

**Alt başlık (App Store, ≤ 30):**
Ye. Şekil kur. Kazan.

**Tam açıklama:**
Futuristic XOX, bildiğin oyuna derinlik katar. Artık taşların sayıları var ve daha zayıf rakip
taşları yiyebilir — her kare bir mücadeleye dönüşür. Klasik X/O oynanışı, orijinali istediğinde diye
ayrı bir mod olarak korunur.

Dört oynanış:
• Klasik — saf üç-taş dizme, 3×3 veya 4×4.
• Original — değerli, yiyen taşlar; üçünü diz ve kazan.
• Bonanza — her oyunda rastgele bir el; bazen rakibinin rengiyle bile oynarsın.
• Morph — her sırada iki taş koy ve dört kareli bir şekli (I, L ya da Z) herhangi bir dönüş, ayna veya
  çapraz hâliyle tamamla.

Özellikler:
• Yerel arama motoruyla üç yapay zekâ zorluğu — Zor gerçekten direnir.
• Akıcı, 60fps metalik tahta ve sürekli kazanma çizgisi.
• Her mod için etkileşimli eğitimler.
• Aynı cihazda sırayla iki kişilik oyun.
• Dört dil, açık & koyu tema, ayarlanabilir ses efektleri.
• Tamamen çevrimdışı. Reklam yok. Takip yok. Hesap yok.

**Anahtar kelimeler:**
xox,tic tac toe,strateji,kutu oyunu,yeme,bulmaca,çevrimdışı,2 kişilik,morph,klasik

---

## Privacy (both stores)

The app collects **no** personal data, has no analytics, and no ads. Gameplay is fully offline; the
only network use is `google_fonts`, which may fetch the display fonts from Google's CDN once on first
launch and cache them (no personal data is sent). The only contact point is a support email the user
chooses to write to. A one-line privacy policy:
"Futuristic XOX does not collect, store, or share any personal data."

> **Release recommendation:** bundle the fonts (Cinzel, Rajdhani, Noto Sans) as assets so the app is
> genuinely offline on first launch and the listing can claim zero network use. Tracked as a v1.0.0
> follow-up alongside background music.
