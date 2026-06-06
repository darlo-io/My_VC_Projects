import 'package:flutter/material.dart';

import '../../../shared/widgets/coming_soon.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Учить',
      icon: Icons.school_outlined,
    );
  }
}
