# Bundled Fonts

All fonts in this directory are licensed under the **SIL Open Font License, Version 1.1**
(OFL-1.1). They are bundled into the application binary for offline-first operation
(no runtime font fetching, no CDN dependency).

| Family | Weights | Source | License file |
|---|---|---|---|
| [Amiri](https://github.com/google/fonts/tree/main/ofl/amiri) | 400, 700 | `google/fonts` (originally by Khaled Hosny) | [`amiri/OFL.txt`](amiri/OFL.txt) |
| [Inter](https://github.com/google/fonts/tree/main/ofl/inter) | 100–900 (variable) | `google/fonts` (originally by Rasmus Andersson) | [`inter/OFL.txt`](inter/OFL.txt) |
| [Cormorant Garamond](https://github.com/google/fonts/tree/main/ofl/cormorantgaramond) | 100–900 (variable) | `google/fonts` (originally by Christian Thalmann / Catharsis Fonts) | [`cormorantgaramond/OFL.txt`](cormorantgaramond/OFL.txt) |

## Usage in the app

* **Amiri** — `fontFamily: 'Amiri'` is used for all Arabic text (ayahs, surah names,
  display variants). See `lib/core/theme/app_typography.dart`.
* **Inter** — bundled for Latin-script UI text. Referenced in the static
  `TextTheme` (see `app_typography.dart`).
* **Cormorant Garamond** — bundled for future display use (e.g. surah-name
  headers). Not yet referenced from code.

## License summary (OFL-1.1)

Permissions:
* Free use, study, modification, and redistribution
* Can be bundled into proprietary / closed-source software

Requirements:
* Keep the original copyright notice and license text with the font
* Modifications must be clearly marked as such
* The font name may not be used to endorse derived works

Full text: <https://scripts.sil.org/OFL>
