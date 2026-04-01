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
  // Variable para saber que pantalla está activa --> 0 = Home
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
  
  // Si pulsamos el boton, cambiamos la variable que nos dice que pantalla mostrar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChangeNotifierProvider(
        create: (_) => HomeProvider(),
        child: HomeScreen(onNavigate: _onItemTapped),
      ),
      const SetsListScreen(customTitle: 'Buscar Sets'),//Indice 1: Buscar sets
      const ExploreScreen(), // Índice 2: Categorias
      const CollectionScreen(), // Índice 1: Coleccion
      const WishlistScreen(), //Indice 2: Lista de deseados
      const SettingsScreen(), // Índice 4: Ajustes
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si mide menos de 640 píxeles de ancho -> MÓVIL.
        bool isMobile = constraints.maxWidth < 640;

        bool showBottomBar = isMobile && _selectedIndex != 0;

        // Scaffold es la estructura básica de una pantalla en Flutter/Kotlin
        return Scaffold(
          extendBody: true,
          // Si NO es móvil -> PC, barra lateral
          // Si ES móvil -> Movil, barra inferior
          body: Row(
            children: [
              if (_selectedIndex != 0) ...[
                NavigationRail(
                  backgroundColor: const Color(0xFF1E1E1E),
                  selectedIndex:
                      _selectedIndex, // Nos indica que icone está seleccionado (para pintarlo)
                  onDestinationSelected:
                      _onItemTapped, // Llama a la funcion que cambia la pantalla
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(color: Colors.orange),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                  selectedIconTheme: const IconThemeData(color: Colors.orange),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  // Destinos laterales (Para PC)
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Buscar Set'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: Text('Categorías'),
                    ),
                    // NUEVO ICONO COLECCIÓN (PC)
                    NavigationRailDestination(
                      icon: Icon(Icons.shelves), // Icono de estantería
                      selectedIcon: Icon(Icons.shelves),
                      label: Text('Colección'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite_border),
                      label: Text('Deseados'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_circle),
                      selectedIcon: Icon(Icons.account_circle),
                      label: Text(_username),
                    ),
                  ],
                ),
                // Línea para separar
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.white10,
                ),
                if (_selectedIndex != 0)
                  const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
              ],

              // EL CONTENIDO PRINCIPAL
              // En lo que sobra mustra la pantalla dependiendo de la variable _selectedIndex
              Expanded(child: NotificationListener<UserScrollNotification>(
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
                )
              ),
            ],
          ),

          // BARRA INFERIOR -> Movil
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
              : null, // En PC, la barra de abajo no existe (null)
        );
      },
    );
  }
}
