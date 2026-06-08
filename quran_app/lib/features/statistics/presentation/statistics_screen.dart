import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/coming_soon.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonScreen(
      title: AppLocalizations.of(context).cardStats,
      icon: Icons.insights_rounded,
    );
  }
}
