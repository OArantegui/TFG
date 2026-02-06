import 'package:flutter/material.dart';
import 'screens/main_layout.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),

        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      home: const MainLayout(),
    );
  }
}
