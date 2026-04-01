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
  int _selectedIndex = 0;
  String _username = "Perfil";
  bool _isBottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final userData = await AuthService().getUserData();
    if (mounted) {
      setState(() {
        _username = userData['username'] ?? 'Perfil'; 
      });
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isBottomBarVisible = true; // Restaurar la barra móvil al cambiar de pestaña
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChangeNotifierProvider(
        create: (_) => HomeProvider(),
        child: HomeScreen(onNavigate: _onItemTapped),
      ),
      const SetsListScreen(customTitle: 'Buscar Sets'),
      const ExploreScreen(),
      const CollectionScreen(),
      const WishlistScreen(),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint clásico: menos de 640px es móvil
        bool isMobile = constraints.maxWidth < 640;

        // La barra inferior SOLO se muestra en móvil Y si NO estamos en la Home
        bool showBottomBar = isMobile && _selectedIndex != 0;

        return Scaffold(
          extendBody: true, // Scroll fluido por debajo de la barra inferior

          body: Row(
            children: [
              // BARRA LATERAL (PC/WEB) - Siempre visible si NO es móvil
              if (!isMobile) ...[
                NavigationRail(
                  backgroundColor: const Color(0xFF1E1E1E),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(color: Colors.orange),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                  selectedIconTheme: const IconThemeData(color: Colors.orange),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Inicio'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Buscar'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: Text('Temas'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.shelves), 
                      selectedIcon: Icon(Icons.shelves),
                      label: Text('Colección'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite_border),
                      label: Text('Deseados'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.account_circle),
                      selectedIcon: const Icon(Icons.account_circle),
                      label: Text(_username),
                    ),
                  ],
                ),
                // Separador vertical nativo (solo uno)
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
              ],

              // CONTENIDO PRINCIPAL
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    // La lógica del scroll solo afecta a la variable de la barra inferior
                    if (isMobile) {
                      if (notification.direction == ScrollDirection.reverse) {
                        if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
                      } else if (notification.direction == ScrollDirection.forward) {
                        if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
                      }
                    }
                    return false;
                  },
                  child: screens[_selectedIndex],
                ),
              ),
            ],
          ),

          // BARRA INFERIOR (MÓVIL)
          bottomNavigationBar: showBottomBar
              ? AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
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
      },
    );
  }
}