import 'package:flutter/material.dart';

import 'src/screens/menu_screens.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const FuturisticXoxApp());
}

class FuturisticXoxApp extends StatelessWidget {
  const FuturisticXoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuristic XOX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const EntryScreen(),
    );
  }
}
