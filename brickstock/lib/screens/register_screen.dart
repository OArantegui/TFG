import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Navegaremos aquí si ya tiene cuenta
import '../widgets/avatar_picker_dialog.dart';

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
  final _confirmPasswordController =
      TextEditingController(); //Controlador para confirmar

  final _authService = AuthService();
  bool _isLoading = false;

  // Variables para controlar la visibilidad de las contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedAvatar = 'assets/avatars/lego-default.jpg';

  // Método para liberar los controladores de la memoria cuando se cierra la pantalla
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _hacerRegistro() async {
    // Validación rápida del frontend antes de molestar al backend
    if (!_formKey.currentState!.validate()) return;

    //  Validación extra de seguridad por si falla el validador del Form
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final bool isSuccess = await _authService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedAvatar,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Por favor, inicia sesión.'),
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
          child: Form(
            // Usamos Form para englobar los campos y validarlos juntos
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(_selectedAvatar),
                        backgroundColor: const Color(0xFF2D2D2D),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AvatarPickerDialog(
                              onAvatarSelected: (avatarPath) {
                                // Al elegir uno, actualizamos la vista al instante
                                setState(() {
                                  _selectedAvatar = avatarPath;
                                });
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Introduce un nombre de usuario' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (val) => val!.isEmpty || !val.contains('@')
                      ? 'Introduce un correo válido'
                      : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Vinculado a la variable
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    // Botón del ojo para mostrar/ocultar
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) =>
                      val!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 15),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText:
                      _obscureConfirmPassword, //  Vinculado a su propia variable
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    //  Botón del ojo para mostrar/ocultar
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  // Validación directa en el formulario
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Por favor, confirma tu contraseña';
                    }
                    if (val != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _hacerRegistro,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  ),
                  child: const Text('¿Ya tienes cuenta? Iniciar Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
