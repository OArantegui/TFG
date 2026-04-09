import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import 'register_screen.dart'; 
import '../providers/user_provider.dart';

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
  bool _keepSignedIn = true; // Variable de estado para el checkbox

  void _hacerLogin() async {
    // Validaciones básicas de campos vacíos
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // Le pasamos al servicio si queremos mantener la sesión
    final bool isSuccess = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      keepSignedIn: _keepSignedIn, // Checkbox
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      await Provider.of<UserProvider>(context, listen: false).loadUserData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al entrar. Revisa credenciales.'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BrickStock - Acceso')),
      body: Center(
        child: SingleChildScrollView(
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
                  prefixIcon: Icon(Icons.email)
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.lock)
                ),
              ),
              const SizedBox(height: 10),

              // ¡NUEVO! Widget nativo para el checkbox
              CheckboxListTile(
                title: const Text("Mantener sesión iniciada"),
                value: _keepSignedIn,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _keepSignedIn = value ?? true;
                  });
                },
              ),
              
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _hacerLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                  child: const Text('Entrar', style: TextStyle(fontSize: 18)),
                ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const RegisterScreen())
                ),
                child: const Text('¿No tienes cuenta? Regístrate'),
              )
            ],
          ),
        ),
      ),
    );
  }
}