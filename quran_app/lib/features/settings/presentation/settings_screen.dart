import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';

// Surfaced through the top-level function `resetAllUserData` in
// `app/providers.dart` so we can call it from the Settings screen
// without threading the entire DI graph into a private helper.
// The actual wipe runs in a single Drift transaction (see
// AppDatabase.wipeUserData) and clears both Drift tables and the
// SharedPreferences keys owned by [AppPreferences].

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final lang = ref.watch(languageProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            t.navProfile,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(text: t.settings),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.language,
                  title: t.settingsLanguage,
                  trailing: Text(
                    _langLabel(t, lang),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showLangSheet(context, ref, t),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.text_fields,
                  title: t.settingsFontSize,
                  trailing: Text(
                    '${prefs.fontSize.round()}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showFontSheet(context, ref, t),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.translate,
                  title: t.settingsTranslation,
                  trailing: Text(
                    prefs.translationLang,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showTrSheet(context, ref, t),
                ),
                const Divider(height: 1),
                _ReciterTile(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(text: t.settingsAudioCache),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _CacheUsageTile(),
                const Divider(height: 1),
                _CacheLimitTile(),
                const Divider(height: 1),
                _ClearCacheTile(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(text: t.settingsAbout),
          const SizedBox(height: 8),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: t.settingsVersion('1.0.0'),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.restart_alt,
                  title: t.settingsReset,
                  onTap: () => _confirmReset(context, ref, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _langLabel(AppLocalizations t, String? code) {
    switch (code) {
      case 'ru':
        return t.languageRussian;
      case 'en':
        return t.languageEnglish;
      case 'ar':
        return t.languageArabic;
      default:
        return t.languageSystem;
    }
  }

  Future<void> _setLang(WidgetRef ref, BuildContext context, String? code) async {
    await ref.read(languageProvider.notifier).set(code);
    if (context.mounted) Navigator.pop(context);
  }

  void _showLangSheet(BuildContext context, WidgetRef ref, AppLocalizations t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.languageRussian),
              onTap: () => _setLang(ref, context, 'ru'),
            ),
            ListTile(
              title: Text(t.languageEnglish),
              onTap: () => _setLang(ref, context, 'en'),
            ),
            ListTile(
              title: Text(t.languageArabic),
              onTap: () => _setLang(ref, context, 'ar'),
            ),
            ListTile(
              title: Text(t.languageSystem),
              onTap: () => _setLang(ref, context, null),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSheet(BuildContext context, WidgetRef ref, AppLocalizations t) {
    const sizes = [20.0, 24.0, 28.0, 32.0, 36.0];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes
              .map(
                (s) => ListTile(
                  title: Text(
                    t.fontPreviewSurah,
                    style: TextStyle(fontSize: s, fontFamily: 'Amiri'),
                  ),
                  trailing: ref.read(appPreferencesProvider).fontSize == s
                      ? const Icon(Icons.check, color: AppColors.gold)
                      : null,
                  onTap: () async {
                    await ref.read(appPreferencesProvider).setFontSize(s);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showTrSheet(BuildContext context, WidgetRef ref, AppLocalizations t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in const ['ru', 'en'])
              ListTile(
                title: Text(l == 'ru' ? t.languageRussian : t.languageEnglish),
                trailing:
                    ref.read(appPreferencesProvider).translationLang == l
                        ? const Icon(Icons.check, color: AppColors.gold)
                        : null,
                onTap: () async {
                  await ref
                      .read(appPreferencesProvider)
                      .setTranslationLang(l);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t.settingsReset),
        content: Text(t.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () async {
              // Закрываем диалог сразу, чтобы избежать двойного
              // нажатия. Дальше — асинхронный wipe и переход на
              // онбординг. Сохраняем `outerCtx` (он = context,
              // пришедший в `_confirmReset`), чтобы не зависеть
              // от `dialogCtx` после `Navigator.pop`.
              final outerCtx = context;
              final outerRef = ref;
              Navigator.pop(dialogCtx);
              try {
                await resetAllUserData(outerRef);
                if (!outerCtx.mounted) return;
                ScaffoldMessenger.of(outerCtx).showSnackBar(
                  SnackBar(content: Text(t.settingsResetDone)),
                );
                // Перекидываем на онбординг, чтобы пользователь
                // заново выбрал язык. Settings route уйдёт
                // из стека, контент-готовность пересоздастся.
                outerCtx.go('/onboarding');
              } catch (e) {
                if (!outerCtx.mounted) return;
                ScaffoldMessenger.of(outerCtx).showSnackBar(
                  SnackBar(
                    content: Text(t.settingsResetFailed('$e')),
                  ),
                );
              }
            },
            child: Text(t.settingsResetConfirmAction),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                )),
      onTap: onTap,
    );
  }
}

/// Реальное использование аудио-кеша: X MB / Y MB.
class _CacheUsageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final totalAsync = ref.watch(cacheTotalBytesProvider);
    final limitMb = ref.watch(cacheLimitMbProvider);
    return ListTile(
      leading: const Icon(
        Icons.sd_storage_outlined,
        color: AppColors.gold,
      ),
      title: Text(
        totalAsync.when(
          data: (bytes) {
            final usedMb = (bytes / (1024 * 1024)).toStringAsFixed(1);
            return t.settingsStorageUsed(usedMb, '$limitMb');
          },
          loading: () => '—',
          error: (_, _) => '—',
        ),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      subtitle: LinearProgressIndicator(
        value: totalAsync.maybeWhen(
          data: (bytes) {
            final max = limitMb * 1024 * 1024;
            return max <= 0 ? 0 : (bytes / max).clamp(0.0, 1.0);
          },
          orElse: () => 0,
        ),
        minHeight: 4,
        backgroundColor: AppColors.borderSubtle,
        valueColor: const AlwaysStoppedAnimation(AppColors.gold),
      ),
    );
  }
}

/// Tile со слайдером для выбора лимита кеша (256 MB..8 GB).
class _CacheLimitTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final limitMb = ref.watch(cacheLimitMbProvider);
    return ListTile(
      leading: const Icon(Icons.tune, color: AppColors.gold),
      title: Text(
        t.settingsCacheLimit,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: Text(
        t.settingsCacheLimitValue(limitMb),
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _showLimitSheet(context, ref),
    );
  }

  void _showLimitSheet(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final prefs = ref.read(appPreferencesProvider);
    final current = prefs.cacheLimitMb;
    const options = [256, 512, 1024, 2048, 4096, 8192];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  t.settingsCacheLimit,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final mb in options)
                ListTile(
                  title: Text(
                    t.settingsCacheLimitValue(mb),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: mb == current
                      ? const Icon(Icons.check, color: AppColors.gold)
                      : null,
                  onTap: () async {
                    // Через notifier — пересоберёт всех подписчиков
                    // appPreferencesProvider. Затем отдельно
                    // уведомляем cacheLimitMbProvider (он не
                    // наследует от appPreferencesProvider).
                    await ref
                        .read(appPreferencesProvider)
                        .setCacheLimitMb(mb);
                    ref.read(cacheLimitMbProvider.notifier).state = mb;
                    // Запустить eviction под новый лимит, не дожидаясь
                    // следующей загрузки.
                    final evicted = await ref
                        .read(audioCacheProvider)
                        .evictIfNeeded(maxBytes: mb * 1024 * 1024);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    if (evicted > 0) {
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        SnackBar(
                          content: Text(t.settingsCacheEvicted(evicted)),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Кнопка полной очистки кеша с подтверждением.
class _ClearCacheTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(
        Icons.delete_sweep_outlined,
        color: AppColors.gold,
      ),
      title: Text(
        t.settingsClearCache,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(t.settingsClearCache),
            content: Text(t.settingsCacheClearConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(t.ok),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await ref.read(audioCacheProvider).clearAll();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.settingsCacheCleared)),
        );
      },
    );
  }
}

/// Settings tile that surfaces the currently-selected audio
/// reciter (read from [AppPreferences.reciterId]) and lets the
/// user pick a different one via a modal bottom sheet.
///
/// Why this lives in [SettingsScreen] rather than [ListenScreen]:
/// the reciter choice is app-wide state, not per-playback
/// state, so it belongs in the persistent-settings UI. The
/// Listen screen still has its own inline reciter carousel for
/// quick per-session swaps — that UX is preserved and writes
/// to the same [AppPreferences.reciterId] key.
class _ReciterTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final activeId = prefs.reciterId;
    return SettingsTile(
      icon: Icons.record_voice_over_outlined,
      title: t.settingsReciter,
      trailing: Text(
        // `reciterNameI` falls back to the English name from
        // the ARB fallback table when ARB doesn't have an
        // entry for this id (e.g. a brand-new reciter added
        // in the seed but not yet translated). The
        // [SurahAndReciterNames] extension centralises this
        // lookup so the Settings tile and the Listen screen
        // can never disagree on the spelling.
        t.reciterName(activeId, fallback: LocalizedNames.reciterEn[activeId] ?? ''),
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showReciterSheet(context, ref, t, activeId),
    );
  }

  void _showReciterSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
    String activeId,
  ) {
    final recitersAsync = ref.watch(recitersStreamProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: recitersAsync.when(
            data: (reciters) => _buildList(
              sheetCtx,
              ref,
              t,
              reciters,
              activeId,
            ),
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => SizedBox(
              height: 120,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '$e',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext sheetCtx,
    WidgetRef ref,
    AppLocalizations t,
    List<Reciter> reciters,
    String activeId,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            t.settingsReciter,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            t.settingsReciterHint,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        for (final r in reciters)
          ListTile(
            title: Text(
              t.reciterName(
                r.id,
                fallback: r.nameEn,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: r.id == activeId
                ? Text(
                    t.settingsReciterActive,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: r.id == activeId
                ? const Icon(Icons.check, color: AppColors.gold)
                : null,
            onTap: () async {
              await ref.read(appPreferencesProvider).setReciterId(r.id);
              if (!sheetCtx.mounted) return;
              Navigator.pop(sheetCtx);
            },
          ),
      ],
    );
  }
}
