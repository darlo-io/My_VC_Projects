import 'package:flutter/material.dart';

import '../../../shared/widgets/coming_soon.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Заучивание',
      icon: Icons.menu_book_rounded,
    );
  }
}
