import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

/// Показать панель заметок для конкретного аята.
///
/// Открывается как `showModalBottomSheet` из [ReaderScreen]. Внутри:
/// - список существующих заметок с кнопкой удалить
/// - пустое состояние, если заметок нет
/// - TextField + "Добавить" для новой заметки
///
/// Стейт полностью реактивный (Drift Streams) — добавление/удаление
/// моментально отражается в UI без ручного `setState`.
Future<void> showNotesPanel({
  required BuildContext context,
  required WidgetRef ref,
  required Ayah ayah,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    builder: (_) => _NotesPanel(ayah: ayah),
  );
}

class _NotesPanel extends ConsumerStatefulWidget {
  const _NotesPanel({required this.ayah});
  final Ayah ayah;

  @override
  ConsumerState<_NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends ConsumerState<_NotesPanel> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(notesDaoProvider).addNote(
            ayahId: widget.ayah.id,
            text: text,
          );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesStream = ref.watch(notesDaoProvider).watchForAyah(widget.ayah.id);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined,
                        color: AppColors.gold, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Заметки к аяту ${widget.ayah.ayahNumber}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 8),
                // Notes list
                Flexible(
                  child: StreamBuilder<List<Note>>(
                    stream: notesStream,
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? const <Note>[];
                      if (notes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note,
                                  size: 40, color: AppColors.textTertiary),
                              SizedBox(height: 8),
                              Text(
                                'Заметок пока нет.\nДобавьте первую ниже.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textTertiary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                          final n = notes[i];
                          return _NoteTile(
                            note: n,
                            onDelete: () => ref
                                .read(notesDaoProvider)
                                .deleteById(n.id),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 8),
                // Composer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_saving,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Текст заметки…',
                          hintStyle: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceHigh,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.textOnGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnGold,
                                ),
                              )
                            : const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onDelete});
  final Note note;
  final VoidCallback onDelete;

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.textValue,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.updatedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textTertiary, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}
