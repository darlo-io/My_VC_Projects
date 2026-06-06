import 'package:flutter/material.dart';

import '../../../shared/widgets/coming_soon.dart';

class ListenScreen extends StatelessWidget {
  const ListenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Слушать',
      icon: Icons.headphones_rounded,
    );
  }
}
