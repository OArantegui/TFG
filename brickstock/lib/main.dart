import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // [IMPORTANTE] Para PointerDeviceKind
import 'screens/main_layout.dart';

void main() {
  runApp(const MyApp());
}

// [NUEVO] Esta clase habilita el arrastre con ratón en Web/PC
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // <--- Esto permite arrastrar con el clic
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrickStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
          background: const Color(0xFF121212),
        ),
        useMaterial3: true,
      ),
      // [IMPORTANTE] Añadimos el comportamiento aquí
      scrollBehavior: MyCustomScrollBehavior(),
      home: const MainLayout(),
    );
  }
}
