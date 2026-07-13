# Quran.com API integration — research & migration plan

**Date**: 2026-07-13
**Status**: Research done, ready for implementation
**Sprint**: 1.1
**Estimated effort**: 4-8 hours (split across Sprint 1 and 2)

## Why migrate

**Current**: mp3quran.net via HTML scraping + manual CDNs
**Issues**:
- 70/7s cumulative rate-limit on Islamic Network CDN
- No structured metadata (no ID3 tags, no reciter metadata)
- No timing data (verse-by-verse timestamps)
- No reliable language/translation support
- DNS hijacking reported in mid-2026 (per existing AGENTS.md note)

**Quran.com API**:
- Official, partnership-based, 30+ reciters with HD
- Structured metadata (qira'at, surah boundaries, reciter.style)
- Verse-level audio URLs (each verse is its own file)
- Per-language translations for reciter names
- 16+ languages for UI
- MseeP.ai security assessed
- Active maintenance

## Endpoints (verified 2026-07-13)

| Endpoint | Purpose | Status |
|---|---|---|
| `GET /api/v4/resources/recitations?language=ru` | Reciter list with Russian names | ✅ 200 OK |
| `GET /api/v4/resources/recitations` | Reciter list (English) | ✅ 200 OK |
| `GET /api/v4/recitations/{id}/by_chapter/{chapter_id}` | Audio URLs for all verses in a chapter | ✅ 200 OK |
| `GET /api/v4/chapters/{id}?language=ru` | Chapter info (name, verses_count, bismillah_pre) | ✅ 200 OK |
| `GET /api/v4/quran/verses/uthmani?verse_key={chapter}:{verse}` | Per-verse Uthmani text | ✅ 200 OK |
| `https://verses.quran.com/{reciter_path}/mp3/{sssnnn}.mp3` | Audio file CDN (BunnyCDN) | ✅ 200 OK |
| `GET /api/v4/resources/tafsirs?language=ru` | Tafsir list (Sprint 2) | TBD |

## Sample responses

### Recitations list (Russian, partial)
```json
{
  "recitations": [
    {
      "id": 7,
      "reciter_name": "Mishari Rashid al-`Afasy",
      "style": null,
      "translated_name": {
        "name": "Mishari Rashid al-`Afasy",
        "language_name": "english"
      }
    },
    {
      "id": 12,
      "reciter_name": "Mahmoud Khalil Al-Husary",
      "style": "Muallim",
      "translated_name": {
        "name": "Махмуд Халиль Аль-Хусари",
        "language_name": "russian"
      }
    }
  ]
}
```

### Chapter audio (reciter 7, chapter 1, partial)
```json
{
  "audio_files": [
    {"verse_key": "1:1", "url": "Alafasy/mp3/001001.mp3"},
    {"verse_key": "1:2", "url": "Alafasy/mp3/001002.mp3"}
  ]
}
```

URL pattern: `{reciter_path}/mp3/{sss}{nnn}.mp3` where `sss` is 3-digit surah, `nnn` is 3-digit verse.

## Migration plan

### Phase 1 (Sprint 1) — Schema + dual-source
- [ ] Add `reciterPath` field to `Reciter` table (DB migration v16+)
- [ ] Add `quranComId` field (canonical reciter id from Quran.com)
- [ ] Add `quranComStyle` field (Murattal, Mujawwad, etc.)
- [ ] Add `QuranComApi` class (`lib/features/audio/data/quran_com_api.dart`)
- [ ] Map current 8 default reciters to Quran.com ids:
  - `ar.alafasy` → id 7 (Mishari Rashid al-`Afasy)
  - `ar.abdulbasitmurattal` → id 1 (AbdulBaset AbdulSamad Murattal)
  - `ar.abdulbasitmujawwad` → id 2 (AbdulBaset AbdulSamad Mujawwad)
  - `ar.husary` → id 6 (Mahmoud Khalil Al-Husary)
  - `ar.minshawi` → id 9 (Mishari Mujawwad)
  - `ar.abdurrahmaansudais` → id 3 (Abdur-Rahman as-Sudais)
  - `ar.saaborimadina` → need to find (probably 11 Sa`ud ash-Shuraym or similar)
  - `ar.hudhaify` → id 4 (Abu Bakr al-Shatri — not exact match)
  - `ar.ahmedajamy` → id 5 (Hani ar-Rifai — not exact match)
- [ ] `resolveSurahUrl(reciter, surahId)` — implement with Quran.com as primary
- [ ] `QuranComRecitationsRepository.syncFromApi()` — fetch from /v4/resources/recitations

### Phase 2 (Sprint 2) — Verse-level audio + timing
- [ ] Switch from per-surah files to per-verse files (better seek precision)
- [ ] Add `quranComAudioTiming` for verse-by-verse highlighting
- [ ] Use `quranComSurahTotal` from chapter info API
- [ ] Use `bismillah_pre` flag from chapter info (some surahs have separate bismillah)

### Phase 3 (Sprint 2-3) — Tafsirs
- [ ] Add `quran_com_tafsir_api.dart` for tafsir data
- [ ] DB table `tafsirs` with verse_id, tafsir_id, text
- [ ] UI: tafsir button in AyahPanel
- [ ] Multiple tafsirs selectable in settings (Ibn Kathir, Jalalayn, Maududi)

## Risks

- **ID migration**: existing cached files use `mp3quran:NNN` format. Need dual-source resolver for backward compat.
- **Network**: Quran.com CDN may be slow/regional. Need health checks.
- **Translation gap**: not all reciters have Russian translated_name. Fallback to English.
- **Audio format**: per-verse files = more HTTP requests = more network. But better seek precision.

## Code structure (planned)

```
lib/features/audio/data/
├── quran_com_api.dart           # NEW — DTOs + REST client
├── quran_com_tafsir_api.dart     # Sprint 2
├── mp3quran_api.dart            # DEPRECATED — keep for backward compat
├── reciters_repository.dart     # MODIFIED — dual source, primary Quran.com
├── audio_player_controller.dart # MODIFIED — use new resolveSurahUrl
└── audio_cache.dart             # MODIFIED — CDN path from reciterPath
```
