import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../data/reciters_repository.dart';

/// Экран полного списка чтецов с поиском.
///
/// Открывается по нажатию «Все чтецы» на [ListenScreen]. Берёт
/// полный список (~241 ректор) из БД, который предварительно
/// заполняется [RecitersRepository.syncFromApi]. Поиск работает
/// по обеим колонкам `nameAr` + `nameEn` (case-insensitive,
/// substring). При тапе на ректор вызывает [onSelect] и закрывается.
///
/// Кнопка «Обновить список» в правом верхнем углу вызывает
/// `syncFromApi()` в фоне — нужно для первой установки или если
/// кэш устарел.
class ReciterPickerScreen extends ConsumerStatefulWidget {
  const ReciterPickerScreen({super.key, required this.onSelect});

  /// Callback на родительском экране — обновит `selectedReciterId`.
  final ValueChanged<Reciter> onSelect;

  @override
  ConsumerState<ReciterPickerScreen> createState() =>
      _ReciterPickerScreenState();
}

class _ReciterPickerScreenState extends ConsumerState<ReciterPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _syncing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(recitersRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор чтеца'),
        actions: [
          IconButton(
            tooltip: 'Обновить список',
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _syncing ? null : _syncFromApi,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Reciter>>(
              stream: repo.watchAll(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final filtered = _query.isEmpty
                    ? all
                    : all.where((r) {
                        final q = _query;
                        final matchEn = (r.nameEn ?? '').toLowerCase().contains(q);
                        return r.nameAr.toLowerCase().contains(q) || matchEn;
                      }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'Нет чтецов. Нажмите «Обновить список».'
                                : 'Ничего не найдено по «$_query».',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ReciterTile(
                    reciter: filtered[i],
                    locale: Localizations.localeOf(context),
                    onTap: () {
                      widget.onSelect(filtered[i]);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncFromApi() async {
    setState(() => _syncing = true);
    try {
      final n = await ref
          .read(recitersRepositoryProvider)
          .syncFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Загружено $n чтецов с mp3quran.net'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

/// Helper: display name в зависимости от текущей локали устройства.
///
/// Приоритет:
///   ru (если локаль ru-RU)
///   en (если локаль en-* или локаль ru отсутствует)
///   ar (fallback — есть у всех ректоров)
///
/// Если конкретная локаль не загружена (mp3quran.net не отдаёт), пробуем
/// следующую в списке. Это упрощает UX — пользователь видит имя на
/// понятном ему языке или хотя бы арабский транслит.
String _displayNameForLocale(Reciter r, Locale locale) {
  final isRu = locale.languageCode.toLowerCase() == 'ru';
  if (isRu && (r.nameRu ?? '').isNotEmpty) return r.nameRu!;
  if ((r.nameEn ?? '').isNotEmpty) return r.nameEn!;
  return r.nameAr;
}

/// Subtitle: сначала rewaya (короткая форма) — это disambiguator
/// для ректоров с одинаковыми именами, потом арабское/английское
/// имя, потом slug.
String _subtitleForLocale(Reciter r, Locale locale) {
  final isRu = locale.languageCode.toLowerCase() == 'ru';
  final display = _displayNameForLocale(r, locale);
  final rewaya = shortRewaya(r.mp3quranRewaya);
  if (rewaya != null && rewaya.isNotEmpty) return rewaya;
  String? native;
  if (isRu) {
    native = (r.nameEn != null && r.nameEn != display) ? r.nameEn : r.nameAr;
  } else {
    native = (r.nameAr != display) ? r.nameAr : r.nameEn;
  }
  if (native != null && native.isNotEmpty) return native;
  return r.slug;
}

/// Tile одного ректора в списке выбора.
class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.onTap,
    required this.locale,
  });

  final Reciter reciter;
  final VoidCallback onTap;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final hasMp3quran = reciterHasAudio(reciter);
    // Display name: ru → en → ar (по коду локали устройства).
    final displayName = _displayNameForLocale(reciter, locale);
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            hasMp3quran ? Theme.of(context).colorScheme.primary : Colors.grey,
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitleForLocale(reciter, locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: hasMp3quran
          ? Icon(
              Icons.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Theme.of(context).disabledColor,
            ),
    );
  }
}