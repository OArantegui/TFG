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
  bool _keepSignedIn = true;

  void _hacerLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final bool isSuccess = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      keepSignedIn: _keepSignedIn,
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
      
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('BrickStock - Acceso'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 8, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
              ),
              color: const Color(0xFF2D2D2D), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_person, size: 70, color: Colors.orange),
                    const SizedBox(height: 10),
                    const Text(
                      'Bienvenido de nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico', 
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ), 
                        prefixIcon: const Icon(Icons.email, color: Colors.white70)
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña', 
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ), 
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70)
                      ),
                    ),
                    const SizedBox(height: 10),

                    CheckboxListTile(
                      title: const Text("Mantener sesión iniciada", style: TextStyle(color: Colors.white70)),
                      value: _keepSignedIn,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.orange,
                      checkColor: Colors.black,
                      onChanged: (bool? value) {
                        setState(() {
                          _keepSignedIn = value ?? true;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 25),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.orange))
                    else
                      ElevatedButton(
                        onPressed: _hacerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // Botón llamativo
                          foregroundColor: Colors.black, // Texto negro para contraste
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const RegisterScreen())
                      ),
                      style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}