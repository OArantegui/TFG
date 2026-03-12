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

  // --- FUNCIÓN DE LOGIN ---
  void _hacerLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final bool isSuccess = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido a BrickStock!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al entrar. Revisa el email y contraseña.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FUNCIÓN DE REGISTRO (¡NUEVA!) ---
  void _hacerRegistro() async {
    FocusScope.of(context).unfocus();

    // Validación básica en el frontend
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduce un email válido y una contraseña de min. 6 caracteres',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final bool isSuccess = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Ya puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      // Opcional: Podrías hacer que inicie sesión automáticamente aquí
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. ¿Quizás el correo ya existe?'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BrickStock - Acceso')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 30),

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

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Botón de Entrar
              ElevatedButton(
                onPressed: _hacerLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Entrar', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 10),

              // Botón de Registrarse
              OutlinedButton(
                onPressed: _hacerRegistro,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Crear nueva cuenta',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
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
