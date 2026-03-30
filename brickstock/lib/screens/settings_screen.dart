import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Controlador para la doble comprobación
  
  final _authService = AuthService();
  bool _isLoading = false;

  void _guardarAjustes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _authService.updateProfile(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustes guardados correctamente'), backgroundColor: Colors.green),
      );
      // Opcional: limpiar las contraseñas tras guardar
      _passwordController.clear();
      _confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar. Puede que el email o usuario ya existan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Deja en blanco los campos que no quieras cambiar.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nuevo Nombre de Usuario', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Nuevo Correo Electrónico', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),

              const Text('Cambio de Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva Contraseña', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar Nueva Contraseña', border: OutlineInputBorder()),
                validator: (val) {
                  // MAGIA AQUÍ: Validación de doble contraseña en frontend
                  if (_passwordController.text.isNotEmpty && val != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _guardarAjustes,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                )
            ],
          ),
        ),
      ),
    );
  }
}