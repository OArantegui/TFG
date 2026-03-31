import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/achievement.dart';
import '../widgets/wishlist_summary_card.dart'; // Importamos el componente reutilizable

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
  final _apiService = ApiService();
  bool _isLoading = false;

  late Future<List<Achievement>> _achievementsFuture;
  late Future<Map<String, dynamic>> _userStatsFuture; // Nuevo Future para las estadísticas

  String _currentUsername = "Coleccionista";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _achievementsFuture = _apiService.getMyAchievements();
    _loadUserStats(); // Cargamos estadísticas al vuelo
  }

  void _loadUserStats() {
    setState(() {
      _userStatsFuture = _fetchUserStats();
    });
  }

  // TFG: Recopilamos datos de la Colección y Wishlist para el panel de estadísticas
  Future<Map<String, dynamic>> _fetchUserStats() async {
    final collection = await _apiService.getUserCollection();
    final wishlistData = await _apiService.getWishlistData();

    final wishlistItems = wishlistData['data'] as List;
    final budget = (wishlistData['budget'] as num).toDouble();
    final totalWishlistValue = wishlistItems.fold(
      0.0,
      (sum, item) => sum + (item['targetPrice'] as num).toDouble(),
    );

    return {
      'collectionCount': collection.length,
      'wishlistCount': wishlistItems.length,
      'wishlistTotal': totalWishlistValue,
      'wishlistBudget': budget,
    };
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
      _cargarDatosUsuario();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar. Puede que el email o usuario ya existan.'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() async {
    await _authService.logout();
    if (!mounted) return;
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
            // --- SECCIÓN 1: CABECERA Y ESTADÍSTICAS ---
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

                  // TFG: Panel de Estadísticas del Usuario
                  FutureBuilder<Map<String, dynamic>>(
                    future: _userStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      }
                      if (snapshot.hasError) {
                        return const Text('Error al cargar estadísticas', style: TextStyle(color: Colors.grey));
                      }

                      final stats = snapshot.data!;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: const Color(0xFF2D2D2D),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.shelves, color: Colors.orange, size: 30),
                                        const SizedBox(height: 8),
                                        Text('${stats['collectionCount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const Text('En Colección', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  color: const Color(0xFF2D2D2D),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.favorite_border, color: Colors.pinkAccent, size: 30),
                                        const SizedBox(height: 8),
                                        Text('${stats['wishlistCount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const Text('En Deseados', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Nuestro nuevo Widget Reutilizable en acción
                          WishlistSummaryCard(
                            totalValue: stats['wishlistTotal'],
                            budget: stats['wishlistBudget'],
                            onBudgetUpdated: _loadUserStats, // Recargamos las stats al guardar
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  
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
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: achievements.length,
                        itemBuilder: (context, index) {
                          final ach = achievements[index];
                          
                          // TFG: Definimos colores y opacidades según estado (reactivo)
                          final Color iconColor = ach.isUnlocked ? Colors.amber : Colors.grey[600]!;
                          final Color backgroundColor = ach.isUnlocked ? Colors.orange.withOpacity(0.2) : const Color(0xFF2D2D2D);
                          final double textOpacity = ach.isUnlocked ? 1.0 : 0.4;

                          return Tooltip(
                            message: ach.description,
                            child: Column( // <-- TFG: Columna principal para Círculo + Texto
                              children: [
                                // --- EL MEDALLÓN CIRCULAR (Nativo Material) ---
                                CircleAvatar(
                                  radius: 35, // Tamaño del círculo
                                  backgroundColor: backgroundColor,
                                  // Borde sutil
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ach.isUnlocked ? Colors.orange.withOpacity(0.5) : Colors.white10,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        ach.iconData,
                                        size: 35, // Tamaño del icono dentro
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 10), // Espacio entre círculo y texto

                                // --- EL TEXTO DEBAJO ---
                                Opacity( // Usamos opacidad para el texto bloqueado
                                  opacity: textOpacity,
                                  child: Text(
                                    ach.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2, // Máximo 2 líneas para que no rompa el grid
                                    overflow: TextOverflow.ellipsis, // Si es muy largo, pone "..."
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: ach.isUnlocked ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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