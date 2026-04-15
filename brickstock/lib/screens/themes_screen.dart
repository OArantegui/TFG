import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/lego_theme.dart';
import 'elements_list_screen.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final ApiService apiService = ApiService();

  List<LegoTheme> _themes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'id_desc';

  @override
  void initState() {
    super.initState();
    _loadThemes(reset: true);
  }

  // reset: true borra la lista y empieza de la página 1
  Future<void> _loadThemes({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _themes.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await apiService.getThemes(
        page: _currentPage,
        search: _searchController.text,
        sort: _currentSort,
      );

      final List results = response['results'];
      final List<LegoTheme> newThemes = results.map((e) => LegoTheme(
        id: e['id'], 
        name: e['name'], 
        fullName: e['fullName'],
        parentId: e['parent_id']
      )).toList();

      setState(() {
        _themes.addAll(newThemes);
        _totalPages = response['totalPages'];
        _totalCount = response['count'];
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      debugPrint('Error cargando temas: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    // Al buscar, reiniciamos la lista para pedir desde la página 1
    _loadThemes(reset: true);
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Container(width: 40, height: 5, decoration: const BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              const Text('Ordenar colecciones por', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildSortOption('Nombre (A - Z)', 'name_asc', Icons.sort_by_alpha),
              _buildSortOption('Nombre (Z - A)', 'name_desc', Icons.sort_by_alpha),
              _buildSortOption('Más recientes', 'id_desc', Icons.history),
              _buildSortOption('Más clásicas', 'id_asc', Icons.star),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String sortValue, IconData icon) {
    final bool isSelected = _currentSort == sortValue;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.orange : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.orange) : null,
      onTap: () {
        setState(() => _currentSort = sortValue);
        Navigator.pop(context);
        _loadThemes(reset: true); // Recargamos ordenado desde el servidor
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text('Temas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                    child: TextField(
                      controller: _searchController,
                      // Llama a la API al pulsar "Enter" para no saturar al escribir letra a letra
                      onSubmitted: (value) => _runFilter(value),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.orange,
                      decoration: InputDecoration(
                        hintText: 'Busca un tema y pulsa Enter...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.orange),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _runFilter('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 45, width: 45,
                  decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: IconButton(icon: const Icon(Icons.tune, color: Colors.orange), onPressed: _showSortBottomSheet),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '$_totalCount TEMAS ENCONTRADOS',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _themes.isEmpty
                      ? const Center(child: Text('No se encontraron resultados', style: TextStyle(color: Colors.white54)))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), // El scroll lo hace el ListView padre
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 250, // Ancho máximo deseado por tarjeta en píxeles
                                childAspectRatio: 1.1, 
                                crossAxisSpacing: 16, 
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _themes.length,
                              itemBuilder: (context, index) {
                                return _ThemeCard(key: ValueKey(_themes[index].id), theme: _themes[index]);
                              },
                            ),
                            
                            // BOTÓN DE CARGAR MÁS
                            if (_currentPage < _totalPages)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator(color: Colors.orange)
                                      : OutlinedButton.icon(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                          label: const Text('Ver más colecciones', style: TextStyle(color: Colors.orange)),
                                          onPressed: () {
                                            _currentPage++;
                                            _loadThemes();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.orange),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final LegoTheme theme;
  const _ThemeCard({super.key, required this.theme});

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  final ApiService apiService = ApiService();
  late Future<String?> _coverImageFuture;

  @override
  void initState() {
    super.initState();
    _coverImageFuture = apiService.getThemeCover(widget.theme.id);
  }

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ElementsListScreen(theme: widget.theme))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<String?>(
                future: _coverImageFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Container(color: const Color(0xFF1E1E1E)); // Fondo simple mientras carga
                  }
                  return CachedNetworkImage(
                    imageUrl: _getImageUrl(snapshot.data!),
                    fit: BoxFit.cover, color: Colors.black.withOpacity(0.5), colorBlendMode: BlendMode.darken,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  );
                },
              ),
            ),
            Positioned(left: 0, top: 15, bottom: 15, child: Container(width: 4, decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.horizontal(right: Radius.circular(2))))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    widget.theme.fullName.toUpperCase(), // Usamos fullName en lugar de name
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 13, // Un pelín más pequeño porque el texto será más largo
                      letterSpacing: 0.5
                    ), 
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis
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