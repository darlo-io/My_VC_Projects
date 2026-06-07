import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';

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
                    'Ал-Фатиха',
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
      builder: (_) => AlertDialog(
        title: Text(t.settingsReset),
        content: Text(t.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
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
          error: (_, __) => '—',
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
    final options = const [256, 512, 1024, 2048, 4096, 8192];
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
                    await prefs.setCacheLimitMb(mb);
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
