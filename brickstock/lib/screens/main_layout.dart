import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'collection_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'sets_list_screen.dart';
import '../services/auth_service.dart';
import '../providers/home_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Variable para saber qué pantalla está activa --> 0 = Home
  int _selectedIndex = 0;

  String _username = "Perfil";
  bool _isBottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Disparamos la carga al crear el Layout
  }

  void _loadUsername() async {
    final userData = await AuthService().getUserData();
    if (mounted) {
      setState(() {
        // Si hay nombre guardado lo usamos, si no, dejamos "Perfil" por defecto
        _username = userData['username'] ?? 'Perfil'; 
      });
    }
  }
  
  // Si pulsamos el botón, cambiamos la variable que nos dice qué pantalla mostrar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Al cambiar de pestaña, nos aseguramos de que la barra vuelva a ser visible
      _isBottomBarVisible = true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChangeNotifierProvider(
        create: (_) => HomeProvider(),
        child: HomeScreen(onNavigate: _onItemTapped),
      ),
      const SetsListScreen(customTitle: 'Buscar Sets'), // Índice 1: Buscar sets
      const ExploreScreen(),                            // Índice 2: Categorías
      const CollectionScreen(),                         // Índice 3: Colección
      const WishlistScreen(),                           // Índice 4: Lista de deseados
      const SettingsScreen(),                           // Índice 5: Ajustes
    ];

    // Solo mostramos la barra inferior si NO estamos en la Home (índice 0)
    bool showBottomBar = _selectedIndex != 0;

    return Scaffold(
      extendBody: true, // Permite el scroll suave por debajo de la barra
      
      // EL CONTENIDO PRINCIPAL ENVUELTO EN EL LISTENER DE SCROLL
      // Ya no necesitamos 'Row' ni 'Expanded' al haber quitado la barra lateral
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          // Si scrolleamos hacia abajo (reverse), ocultamos la barra
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
          } 
          // Si scrolleamos hacia arriba (forward), mostramos la barra
          else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
          }
          return false; // Retornar false permite que el scroll siga funcionando
        },
        child: screens[_selectedIndex],
      ),

      // BARRA INFERIOR UNIFICADA (Para móvil y Web)
      bottomNavigationBar: showBottomBar
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              // Offset(0,1) la empuja un 100% de su tamaño hacia abajo (la oculta)
              offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1),
              child: NavigationBar(
                backgroundColor: const Color(0xFF1E1E1E),
                indicatorColor: Colors.orange.withOpacity(0.2),
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.dashboard, color: Colors.orange),
                    label: 'Inicio',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.search, color: Colors.orange),
                    label: 'Buscar',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.list_alt_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.list_alt, color: Colors.orange),
                    label: 'Temas',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.shelves, color: Colors.grey),
                    selectedIcon: Icon(Icons.shelves, color: Colors.orange),
                    label: 'Colección',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.favorite_border, color: Colors.grey),
                    selectedIcon: Icon(Icons.favorite, color: Colors.orange),
                    label: 'Deseados',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_circle, color: Colors.grey),
                    selectedIcon: const Icon(Icons.account_circle, color: Colors.orange),
                    label: _username,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}