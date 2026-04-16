import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Para PointerDeviceKind
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';

void main() {
  runApp(//Envolvemos la app para que el usuario esté disponible en todas las pantallas
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
      ],
      child: const MyApp(),
    ),
    );
}

// Esta clase habilita el arrastre con ratón en Web/PC
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
        ),
        // Fondo por defecto en las pantallas
        scaffoldBackgroundColor: const Color(0xFF121212), 
        
        // Que todas las pantallas sean del mismo color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      scrollBehavior: MyCustomScrollBehavior(),
      home: FutureBuilder<bool>(
        future: AuthService().isLoggedIn(),
        builder: (context, snapshot) {
          // Mientras comprueba, mostramos un indicador de carga limpio
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.orange)),
            );
          }
          
          // Si isLoggedIn devolvió true, vamos a la app. Si no, al Login.
          if (snapshot.data == true) {
            return const MainLayout(); // Cambia esto por el nombre de tu vista principal
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
