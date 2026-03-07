import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Para PointerDeviceKind
import 'screens/main_layout.dart';

void main() {
  runApp(const MyApp());
}

// [NUEVO] Esta clase habilita el arrastre con ratón en Web/PC
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // Nos permite arrstrar en Pc
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrickStock',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
          background: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      scrollBehavior: MyCustomScrollBehavior(),
      home: const MainLayout(),
    );
  }
}
