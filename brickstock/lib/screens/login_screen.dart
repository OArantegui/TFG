import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  // Función que se ejecuta al pulsar el botón
  void _hacerLogin() async {
    // 1. Ocultar el teclado y mostrar el icono de carga
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    // 2. Llamar a tu servidor Node.js
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    // 3. Quitar el icono de carga
    setState(() {
      _isLoading = false;
    });

    // 4. Comprobar el resultado
    if (result['success']) {
      // Si va bien, mostramos un mensaje verde y vamos a la pantalla principal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido!'), backgroundColor: Colors.green),
      );

      // Navegar a la pantalla principal (Home) y no dejar que el usuario vuelva atrás al login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      // Si falla (ej: mala contraseña), mostramos el error de tu backend en rojo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.orange),
            const SizedBox(height: 30),

            // Campo de Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),

            // Campo de Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true, // Oculta el texto con asteriscos
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            // Botón de Login (Muestra un cargador si está pensando)
            ElevatedButton(
              onPressed: _isLoading ? null : _hacerLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Entrar', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
