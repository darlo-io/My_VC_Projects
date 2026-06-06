import 'package:flutter/material.dart';

import '../../../shared/widgets/coming_soon.dart';

class ReciterPickerScreen extends StatelessWidget {
  const ReciterPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Выберите чтеца',
      icon: Icons.record_voice_over_rounded,
    );
  }
}
