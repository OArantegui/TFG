import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Navegaremos aquí si ya tiene cuenta

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // GlobalKey para validar el formulario completo de una vez (Patrón recomendado en Flutter)
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _hacerRegistro() async {
    // Validación rápida del frontend antes de molestar al backend
    if (!_formKey.currentState!.validate()) return; 

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final bool isSuccess = await _authService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Por favor, inicia sesión.'), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. El usuario o correo ya existen.'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BrickStock - Registro')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form( // Usamos Form para englobar los campos y validarlos juntos
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 30),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.person)
                  ),
                  validator: (val) => val!.isEmpty ? 'Introduce un nombre de usuario' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.email)
                  ),
                  validator: (val) => val!.isEmpty || !val.contains('@') ? 'Introduce un correo válido' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.lock)
                  ),
                  validator: (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 30),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _hacerRegistro,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                    child: const Text('Crear cuenta', style: TextStyle(fontSize: 18)),
                  ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const LoginScreen())
                  ),
                  child: const Text('¿Ya tienes cuenta? Iniciar Sesión'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}