import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'collection_screen.dart';
import 'wishlist_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Variable para saber que pantalla está activa --> 0 = Home
  int _selectedIndex = 0;

  // Lista de pantallas
  // final List<Widget> _screens = [
  //   const HomeScreen(), // [0] -> Home
  //   const ExploreScreen(), // [1] -> Explorar
  //   const Center(
  //     child: Text(
  //       'Ajustes (Próximamente)',
  //       style: TextStyle(color: Colors.white),
  //     ),
  //   ), // [2] -> Ajustes
  // ];
  final List<Widget> _screens = [
    const HomeScreen(), // Índice 0: Inicio
    const CollectionScreen(), // Índice 1: Colección
    const WishlistScreen(), //Indice 2: Lista de deseados
    const ExploreScreen(), // Índice 3: Catálogo (Antiguo Explore)
    const Center(child: Text('Ajustes')), // Índice 4: Ajustes provisional
  ];
  // Si pulsamos el boton, cambiamos la variable que nos dice que pantalla mostrar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si mide menos de 640 píxeles de ancho -> MÓVIL.
        bool isMobile = constraints.maxWidth < 640;

        // Scaffold es la estructura básica de una pantalla en Flutter/Kotlin
        return Scaffold(
          // Si NO es móvil -> PC, barra lateral
          // Si ES móvil -> Movil, barra inferior
          body: Row(
            children: [
              if (!isMobile) ...[
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
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Inicio'),
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
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Catálogo'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Ajustes'),
                    ),
                  ],
                ),
                // Línea para separar
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.white10,
                ),
              ],

              // EL CONTENIDO PRINCIPAL
              // En lo que sobra mustra la pantalla dependiendo de la variable _selectedIndex
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),

          // BARRA INFERIOR -> Movil
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  indicatorColor: Colors.orange.withOpacity(0.2),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
                      selectedIcon: Icon(Icons.dashboard, color: Colors.orange),
                      label: 'Inicio',
                    ),
                    // NUEVO ICONO COLECCIÓN (Móvil)
                    NavigationDestination(
                      icon: Icon(Icons.shelves, color: Colors.grey),
                      selectedIcon: Icon(Icons.shelves, color: Colors.orange),
                      label: 'Colección',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border, color: Colors.grey),
                      selectedIcon: Icon(
                        Icons.favorite_border,
                        color: Colors.orange,
                      ),
                      label: 'Deseados',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined, color: Colors.grey),
                      selectedIcon: Icon(Icons.search, color: Colors.orange),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined, color: Colors.grey),
                      selectedIcon: Icon(Icons.settings, color: Colors.orange),
                      label: 'Ajustes',
                    ),
                  ],
                )
              : null, // En PC, la barra de abajo no existe (null)
        );
      },
    );
  }
}
