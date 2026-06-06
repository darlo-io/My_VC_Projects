import 'package:flutter/material.dart';

import '../../../shared/widgets/coming_soon.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Статистика',
      icon: Icons.insights_rounded,
    );
  }
}
