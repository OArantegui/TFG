/*import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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

  List<LegoTheme> _themes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'name_asc';

  @override
  void initState() {
    super.initState();
    _loadThemes(reset: true);
  }

  // reset: true borra la lista y empieza de la página 1 (ideal para buscar u ordenar)
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
              _buildSortOption('Más recientes', 'id_desc', Icons.new_releases),
              _buildSortOption('Más clásicas', 'id_asc', Icons.history),
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
        title: const Text('Catálogos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        hintText: 'Buscar colección y pulsa Enter...',
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
                        '$_totalCount COLECCIONES ENCONTRADAS',
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
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 16, mainAxisSpacing: 16,
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SetsListScreen(theme: widget.theme))),
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
                  child: Text(widget.theme.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/minifigure.dart';
import 'set_details_screen.dart';

// Definimos los tipos de búsqueda para el SegmentedButton
enum SearchType { sets, minifigs }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  // Estado de la búsqueda
  SearchType _selectedSearch = SearchType.sets;
  List<dynamic> _results = []; // Puede contener LegoSet o Minifigure
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch({bool isNextPage = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!isNextPage) {
        _results.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      if (_selectedSearch == SearchType.sets) {
        final data = await _apiService.getAllSets(
          page: _currentPage,
          search: _searchController.text,
        );
        setState(() {
          _results.addAll(data['sets']);
          _hasMore = data['next'] != null;
        });
      } else {
        final data = await _apiService.getAllMinifigs(
          page: _currentPage,
          search: _searchController.text,
        );
        setState(() {
          _results.addAll(data['minifigs']);
          _hasMore = data['next'] != null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Catálogo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // BUSCADOR NATIVO
                SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar por nombre o número...',
                  leading: const Icon(Icons.search),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 10),
                // SEGMENTED BUTTON (Material 3) - ¡Clave para el TFG!
                SegmentedButton<SearchType>(
                  segments: const [
                    ButtonSegment(
                      value: SearchType.sets,
                      label: Text('Sets'),
                      icon: Icon(Icons.inventory_2),
                    ),
                    ButtonSegment(
                      value: SearchType.minifigs,
                      label: Text('Minifiguras'),
                      icon: Icon(Icons.person_pin),
                    ),
                  ],
                  selected: {_selectedSearch},
                  onSelectionChanged: (Set<SearchType> newSelection) {
                    setState(() {
                      _selectedSearch = newSelection.first;
                    });
                    _performSearch();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _results.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _currentPage++;
                        _performSearch(isNextPage: true);
                      },
                      child: const Text('Cargar más'),
                    ),
                  );
                }

                final item = _results[index];
                
                // Renderizado dinámico según el tipo
                if (item is LegoSet) {
                  return ListTile(
                    leading: Image.network(
                      _apiService.getProxyUrl(item.imgUrl),
                      width: 50,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                    title: Text(item.name),
                    subtitle: Text('Set #${item.setNum} • ${item.numParts} piezas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SetDetailsScreen(legoSet: item)),
                    ),
                  );
                } else if (item is Minifigure) {
                  return ListTile(
                    leading: Image.network(
                      _apiService.getProxyUrl(item.imageUrl),
                      width: 50,
                      errorBuilder: (_, __, ___) => const Icon(Icons.face),
                    ),
                    title: Text(item.name),
                    subtitle: Text('Fig #${item.figNum} • ${item.numParts} piezas'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      // Aquí llamaremos a la pantalla de detalles de minifig en el futuro
                      _showAddMinifigDialog(item);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  // Diálogo rápido para añadir minifigura (Cumpliendo el requisito de "añadir a colección")
  void _showAddMinifigDialog(Minifigure fig) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir a Colección'),
        content: Text('¿Quieres añadir a ${fig.name} como pieza suelta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final res = await _apiService.addMinifigToCollection(fig.figNum);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'])),
              );
            }, 
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}