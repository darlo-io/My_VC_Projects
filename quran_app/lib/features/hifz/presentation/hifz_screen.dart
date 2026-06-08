import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/coming_soon.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonScreen(
      title: AppLocalizations.of(context).hifzTitle,
      icon: Icons.menu_book_rounded,
    );
  }
}
