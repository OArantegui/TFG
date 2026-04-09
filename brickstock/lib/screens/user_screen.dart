import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/achievement.dart';
import '../widgets/wishlist_summary_card.dart'; // Importamos el componente reutilizable
import 'login_screen.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../providers/user_provider.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isPasswordUnlocked = false;

  late Future<List<Achievement>> _achievementsFuture;
  late Future<Map<String, dynamic>>
  _userStatsFuture; // Nuevo Future para las estadísticas

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
        const SnackBar(
          content: Text('Ajustes guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _passwordController.clear();
      _confirmPasswordController.clear();
      _cargarDatosUsuario();
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error al guardar. Puede que el email o usuario ya existan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    _isPasswordUnlocked = false;
  }

  void _logout() async {
    await _authService.logout();
    Provider.of<UserProvider>(context, listen: false).clearUserData();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  void _solicitarPasswordActual() {
    // Si ya lo desbloqueó antes, le dejamos escribir normalmente
    if (_isPasswordUnlocked) return;

    final currentPassController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a interactuar con los botones
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 10),
                Text('Seguridad', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Por favor, introduce tu contraseña actual para desbloquear la edición de contraseña.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Actual',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (currentPassController.text.isEmpty) return;

                        // Mostramos el circulito de carga en el botón
                        setStateDialog(() => isVerifying = true);

                        final isValid = await _authService
                            .verifyCurrentPassword(currentPassController.text);

                        if (!mounted) return;
                        setStateDialog(() => isVerifying = false);

                        if (isValid) {
                          setState(() {
                            _isPasswordUnlocked =
                                true; // ¡Desbloqueamos los campos!
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Campos de contraseña desbloqueados',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contraseña incorrecta'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verificar',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              //Destruimos la sesión en la BBDD y en el almacenamiento local
              await AuthService().logout();

              //Comprobación de seguridad nativa de Flutter:
              // Asegurarnos de que esta pantalla sigue existiendo antes de intentar navegar
              if (!context.mounted) return;

              //Navegamos al Login pero DESTRUYENDO todo el historial anterior.
              // Así evitamos que el usuario le dé al botón físico de "Atrás" en Android y vuelva a entrar.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) =>
                    false, // Esto le dice a Flutter: "Elimina todas las rutas"
              );
            },
          ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(
                          context.watch<UserProvider>().avatar,
                        ),
                        backgroundColor: const Color(0xFF2D2D2D),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AvatarPickerDialog(
                              onAvatarSelected: (avatarPath) async {
                                // 1. Guardamos en el servidor
                                final success = await _authService.updateAvatar(
                                  avatarPath,
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  // 2. ¡AVISAMOS AL PROVIDER DEL CAMBIO!
                                  Provider.of<UserProvider>(
                                    context,
                                    listen: false,
                                  ).updateAvatar(avatarPath);

                                  // 3. Actualizamos visualmente la propia pantalla
                                  /*setState(() {
                                    _currentAvatar = avatarPath;
                                  });*/

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Avatar actualizado con éxito',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.watch<UserProvider>().username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TFG: Panel de Estadísticas del Usuario
                  FutureBuilder<Map<String, dynamic>>(
                    future: _userStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Error al cargar estadísticas',
                          style: TextStyle(color: Colors.grey),
                        );
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
                                        const Icon(
                                          Icons.shelves,
                                          color: Colors.orange,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${stats['collectionCount']}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          'En Colección',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
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
                                        const Icon(
                                          Icons.favorite_border,
                                          color: Colors.pinkAccent,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${stats['wishlistCount']}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          'En Deseados',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
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
                            onBudgetUpdated:
                                _loadUserStats, // Recargamos las stats al guardar
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // TFG: Grid de insignias reactivo y con contador
                  FutureBuilder<List<Achievement>>(
                    future: _achievementsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tus Insignias (...)',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Error al cargar insignias',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      final achievements = snapshot.data ?? [];
                      // Calculamos cuántas están desbloqueadas
                      final unlockedCount = achievements
                          .where((a) => a.isUnlocked)
                          .length;
                      final totalCount = achievements.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título dinámico
                          Text(
                            'Tus Insignias ($unlockedCount/$totalCount)',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: achievements.length,
                            itemBuilder: (context, index) {
                              final ach = achievements[index];

                              // TFG: Definimos colores y opacidades según estado (reactivo)
                              final Color iconColor = ach.isUnlocked
                                  ? Colors.amber
                                  : Colors.grey[600]!;
                              final Color backgroundColor = ach.isUnlocked
                                  ? Colors.orange.withOpacity(0.2)
                                  : const Color(0xFF2D2D2D);
                              final double textOpacity = ach.isUnlocked
                                  ? 1.0
                                  : 0.4;

                              return Tooltip(
                                message: ach.description,
                                child: Column(
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
                                            color: ach.isUnlocked
                                                ? Colors.orange.withOpacity(0.5)
                                                : Colors.white10,
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

                                    const SizedBox(
                                      height: 10,
                                    ), // Espacio entre círculo y texto
                                    // --- EL TEXTO DEBAJO ---
                                    Opacity(
                                      // Usamos opacidad para el texto bloqueado
                                      opacity: textOpacity,
                                      child: Text(
                                        ach.name,
                                        textAlign: TextAlign.center,
                                        maxLines:
                                            2, // Máximo 2 líneas para que no rompa el grid
                                        overflow: TextOverflow
                                            .ellipsis, // Si es muy largo, pone "..."
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: ach.isUnlocked
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- SECCIÓN 2: FORMULARIO DE AJUSTES (Acordeón) ---
            ExpansionTile(
              title: const Text(
                'Ajustes de Cuenta',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(Icons.settings, color: Colors.grey),
              childrenPadding: const EdgeInsets.all(16.0),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Deja en blanco la contraseña si no quieres cambiarla.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Usuario',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        readOnly:
                            !_isPasswordUnlocked, // Solo lectura si no está desbloqueado
                        onTap: _solicitarPasswordActual, // ¡Dispara el pop-up!
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          border: const OutlineInputBorder(),
                          // Un icono visual para que sepa si está bloqueado o abierto
                          suffixIcon: Icon(
                            _isPasswordUnlocked ? Icons.lock_open : Icons.lock,
                            color: _isPasswordUnlocked
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        readOnly:
                            !_isPasswordUnlocked, // Solo lectura si no está desbloqueado
                        onTap: _solicitarPasswordActual, // ¡Dispara el pop-up!
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            _isPasswordUnlocked ? Icons.lock_open : Icons.lock,
                            color: _isPasswordUnlocked
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        validator: (val) {
                          if (_passwordController.text.isNotEmpty &&
                              val != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _guardarAjustes,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
