import 'package:flutter/material.dart';
import 'screens/explore_screen.dart';

void main() {
  runApp(const BrickStockApp());
}

class BrickStockApp extends StatelessWidget {
  const BrickStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrickStock',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        // Estilo "Anti-Diseño" limpio y profesional
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const ExploreScreen(),
    );
  }
}