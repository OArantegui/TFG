import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/achievement.dart';

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
  final _confirmPasswordController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;

  late Future<List<Achievement>> _achievementsFuture;
  String _currentUsername = "Coleccionista";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    // TFG: Disparamos la carga de insignias al iniciar la vista
    _achievementsFuture = ApiService().getMyAchievements();
  }

  void _cargarDatosUsuario() async {
    final userData = await _authService.getUserData();
    setState(() {
      _currentUsername = userData['username'] ?? 'Coleccionista';
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
    });
  }

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
      _passwordController.clear();
      _confirmPasswordController.clear();
      _cargarDatosUsuario(); // Actualizamos el título
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar. Puede que el email o usuario ya existan.'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
    // Volvemos a la pantalla de login borrando el historial de navegación
    Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          )
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN 1: CABECERA Y LOGROS ---
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUsername,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tus Insignias', style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),

                  // TFG: Grid de insignias reactivo
                  FutureBuilder<List<Achievement>>(
                    future: _achievementsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      }
                      if (snapshot.hasError) {
                        return const Text('Error al cargar insignias', style: TextStyle(color: Colors.grey));
                      }

                      final achievements = snapshot.data ?? [];
                      
                      return GridView.builder(
                        shrinkWrap: true, // Vital dentro de un SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 columnas puras
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final ach = achievements[index];
                          return Tooltip(
                            message: ach.description,
                            child: Card(
                              color: ach.isUnlocked ? const Color(0xFF2D2D2D) : Colors.transparent,
                              elevation: ach.isUnlocked ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: ach.isUnlocked ? Colors.orange.withOpacity(0.5) : Colors.white10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ach.iconData,
                                    size: 40,
                                    color: ach.isUnlocked ? Colors.amber : Colors.grey.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ach.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: ach.isUnlocked ? Colors.white : Colors.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- SECCIÓN 2: FORMULARIO DE AJUSTES (Acordeón) ---
            ExpansionTile(
              title: const Text('Ajustes de Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.settings, color: Colors.grey),
              childrenPadding: const EdgeInsets.all(16.0),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Deja en blanco la contraseña si no quieres cambiarla.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Nombre de Usuario', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),

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
                          if (_passwordController.text.isNotEmpty && val != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: Colors.orange))
                      else
                        ElevatedButton.icon(
                          onPressed: _guardarAjustes,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15)
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}