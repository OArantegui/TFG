import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_theme.dart';
import 'sets_list_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService apiService = ApiService();

  // VARIABLES PARA EL BUSCADOR
  List<LegoTheme> _allThemes = []; // Lista maestra (todos los datos)
  List<LegoTheme> _filteredThemes = []; // Lista visible (lo que mostramos)
  bool _isLoading = true; // Estado de carga
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThemes(); // Carga inicial de datos
  }

  // Carga los datos de la API una sola vez
  Future<void> _loadThemes() async {
    try {
      final themes = await apiService.getThemes();
      setState(() {
        _allThemes = themes;
        _filteredThemes = themes; // Al principio se ve todo
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error cargando temas: $e');
    }
  }

  // Lógica de filtrado (el cerebro del buscador)
  void _runFilter(String enteredKeyword) {
    List<LegoTheme> results = [];
    if (enteredKeyword.isEmpty) {
      // Si borran el texto, volvemos a mostrar todo
      results = _allThemes;
    } else {
      // Filtramos buscando coincidencias (ignorando mayúsculas/minúsculas)
      results = _allThemes
          .where(
            (theme) =>
                theme.name.toLowerCase().contains(enteredKeyword.toLowerCase()),
          )
          .toList();
    }

    // Actualizamos la pantalla con los resultados
    setState(() {
      _filteredThemes = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro base
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        // BARRA DE BÚSQUEDA INTEGRADA EN EL TÍTULO
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D), // Gris oscuro (tecla)
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.orange,
            decoration: const InputDecoration(
              hintText: 'Buscar colección (ej. Star Wars)...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.orange),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // Contador de resultados
                if (!_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredThemes.length} COLECCIONES',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                // GRID DE TARJETAS
                Expanded(
                  child: _filteredThemes.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron resultados',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 columnas
                                childAspectRatio: 1.1, // Formato casi cuadrado
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _filteredThemes.length,
                          itemBuilder: (context, index) {
                            final theme = _filteredThemes[index];
                            return _ThemeCard(theme: theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// TARJETA DE TEMA (DISEÑO KEYCHRON)
class _ThemeCard extends StatelessWidget {
  final LegoTheme theme;

  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetsListScreen(theme: theme)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Imagen de fondo oscurecida
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5), // Capa oscura
                colorBlendMode: BlendMode.darken,
              ),
            ),
            // 2. Decoración naranja lateral
            Positioned(
              left: 0,
              top: 15,
              bottom: 15,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
            ),
            // 3. Texto del tema
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                  ), // Espacio para la barra naranja
                  child: Text(
                    theme.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
