import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'themes_screen.dart';
import 'collection_screen.dart';
import 'wishlist_screen.dart';
import 'user_screen.dart';
import 'elements_list_screen.dart';
import '../services/auth_service.dart';
import '../providers/home_provider.dart';
import '../providers/collection_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String _username = "Perfil";
  bool _isBottomBarVisible = true;

  final GlobalKey<NavigatorState> _exploreNavKey = GlobalKey<NavigatorState>();

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
      if (_selectedIndex == 2 && index == 2) {
        _exploreNavKey.currentState?.popUntil((route) => route.isFirst);
      }
      _selectedIndex = index;
      _isBottomBarVisible = true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChangeNotifierProvider(create: (_) => HomeProvider(), child: HomeScreen(onNavigate: _onItemTapped)),
      const ElementsListScreen(customTitle: 'Buscar Sets'),
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          if (_exploreNavKey.currentState != null && _exploreNavKey.currentState!.canPop()) {
            _exploreNavKey.currentState!.pop();
          } else {
            setState(() => _selectedIndex = 0);
          }
        },
        child: Navigator(
          key: _exploreNavKey,
          onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const ThemesScreen()),
        ),
      ),
      ChangeNotifierProvider(create: (_) => CollectionProvider(), child: const CollectionScreen()),
      const WishlistScreen(),
      const UserScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 640;
        bool showBottomBar = isMobile && _selectedIndex != 0;

        return Scaffold(
          extendBody: true,
          body: Row(
            children: [
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
                    NavigationRailDestination(
                      icon: Image.asset('assets/brickstock_logo.png', width: 24, height: 24, color: Colors.grey), 
                      selectedIcon: Image.asset('assets/brickstock_logo.png', width: 24, height: 24), 
                      label: const Text('Inicio')),
                    const NavigationRailDestination(
                      icon: Icon(Icons.search_outlined), 
                      selectedIcon: Icon(Icons.search), 
                      label: Text('Buscar')),
                    const NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined), 
                      selectedIcon: Icon(Icons.list_alt), 
                      label: Text('Temas')),
                    const NavigationRailDestination(
                      icon: Icon(Icons.shelves), 
                    selectedIcon: Icon(Icons.shelves), 
                    label: Text('Colección')),
                    const NavigationRailDestination(
                      icon: Icon(Icons.favorite_border), 
                      selectedIcon: Icon(Icons.favorite_border), 
                      label: Text('Deseados')),
                    NavigationRailDestination(
                      icon: const Icon(Icons.account_circle), 
                      selectedIcon: const Icon(Icons.account_circle), 
                      label: Text(_username)),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
              ],

              Expanded(
                // === TFG: ESCUCHAMOS LA CLASE BASE 'Notification' ===
                child: NotificationListener<Notification>(
                  onNotification: (Notification notification) {
                    if (isMobile) {
                      // 1. Si la lista CAMBIA DE TAMAÑO bruscamente (ej: borrar búsqueda)
                      if (notification is ScrollMetricsNotification) {
                        if (notification.metrics.maxScrollExtent <= 0 && !_isBottomBarVisible) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _isBottomBarVisible = true);
                          });
                        }
                      }
                      
                      // 2. Si hacemos scroll hasta arriba del todo
                      if (notification is ScrollNotification) {
                        if (notification.metrics.pixels <= 0 || notification.metrics.maxScrollExtent <= 0) {
                          if (!_isBottomBarVisible) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _isBottomBarVisible = true);
                            });
                          }
                        }
                      }

                      // 3. El gesto del dedo (Bajar = Ocultar, Subir = Mostrar)
                      if (notification is UserScrollNotification) {
                        if (notification.direction == ScrollDirection.reverse) {
                          if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
                        } else if (notification.direction == ScrollDirection.forward) {
                          if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
                        }
                      }
                    }
                    return false;
                  },
                  child: screens[_selectedIndex],
                ),
              ),
            ],
          ),
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
                      NavigationDestination(
                        icon: Image.asset('assets/brickstock_logo.png', width: 24, height: 24, color: Colors.grey), 
                        selectedIcon: Image.asset('assets/brickstock_logo.png', width: 24, height: 24), 
                        label: 'Inicio'),
                      const NavigationDestination(
                        icon: Icon(Icons.search_outlined, color: Colors.grey), 
                        selectedIcon: Icon(Icons.search, color: Colors.orange), 
                        label: 'Buscar'),
                      const NavigationDestination(
                        icon: Icon(Icons.list_alt_outlined, color: Colors.grey), 
                        selectedIcon: Icon(Icons.list_alt, color: Colors.orange), 
                        label: 'Temas'),
                      const NavigationDestination(
                        icon: Icon(Icons.shelves, color: Colors.grey), 
                        selectedIcon: Icon(Icons.shelves, color: Colors.orange), 
                        label: 'Colección'),
                      const NavigationDestination(
                        icon: Icon(Icons.favorite_border, color: Colors.grey), 
                        selectedIcon: Icon(Icons.favorite, color: Colors.orange), 
                        label: 'Deseados'),
                      NavigationDestination(
                        icon: const Icon(Icons.account_circle, color: Colors.grey), 
                        selectedIcon: const Icon(Icons.account_circle, color: Colors.orange), 
                        label: _username),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}