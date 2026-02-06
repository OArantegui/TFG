import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Índice para controlar qué pestaña está activa (0 = Home, 1 = Explorar...)
  int _selectedIndex = 0;

  // Lista de pantallas que vamos a mostrar
  final List<Widget> _screens = [
    const HomeScreen(), // Índice 0: Tu Dashboard
    const ExploreScreen(), // Índice 1: El Catálogo
    const Center(
      child: Text(
        'Ajustes (Próximamente)',
        style: TextStyle(color: Colors.white),
      ),
    ), // Índice 2
  ];

  // Función para cambiar de pestaña al pulsar un botón
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // DETECCIÓN DE DISPOSITIVO:
        // Si mide menos de 640 píxeles de ancho, asumimos que es un MÓVIL.
        bool isMobile = constraints.maxWidth < 640;

        return Scaffold(
          // Si NO es móvil (es PC), mostramos un Row con barra lateral (Rail).
          // Si ES móvil, no mostramos nada a los lados (null).
          body: Row(
            children: [
              if (!isMobile) ...[
                NavigationRail(
                  backgroundColor: const Color(0xFF1E1E1E), // Gris muy oscuro
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
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
                // Línea divisoria vertical estética
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.white10,
                ),
              ],

              // EL CONTENIDO PRINCIPAL
              // Expanded hace que la pantalla ocupe todo el espacio sobrante
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),

          // BARRA INFERIOR (Solo visible en MÓVIL)
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  // Estilo Keychron para la barra
                  backgroundColor: const Color(0xFF1E1E1E),
                  indicatorColor: Colors.orange.withOpacity(
                    0.2,
                  ), // Burbuja naranja suave
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
                      selectedIcon: Icon(Icons.dashboard, color: Colors.orange),
                      label: 'Inicio',
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
