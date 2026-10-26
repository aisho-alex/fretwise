import 'package:flutter/material.dart';

import 'ui/screens/training_screen.dart';

class GuitarTrainerApp extends StatelessWidget {
  const GuitarTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF78BFA4),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Гриф — тренажёр нот',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF111613),
        visualDensity: VisualDensity.standard,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
        ),
      ),
      home: const TrainingScreen(),
    );
  }
}
