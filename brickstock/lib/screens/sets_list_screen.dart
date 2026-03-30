/**import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import '../models/lego_theme.dart';
import '../models/lego_set.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class SetsListScreen extends StatefulWidget {
  final LegoTheme theme;

  const SetsListScreen({super.key, required this.theme});

  @override
  State<SetsListScreen> createState() => _SetsListScreenState();
}

class _SetsListScreenState extends State<SetsListScreen> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<LegoSet> _sets = [];
  bool _isLoading = true; // Para la carga inicial
  bool _isLoadingMore = false; // Para cuando hacemos scroll
  bool _hasMore = true; // ¿Quedan más páginas por cargar?
  int _currentPage = 1;
  String _currentSearch = '';
  String? _errorMessage;
  String _currentSort = 'year_desc'; // Orden por defecto real de Rebrickable

  @override
  void initState() {
    super.initState();
    _loadSets();

    // Listener para el scroll infinito
    _scrollController.addListener(() {
      // Si llegamos casi al final de la lista, cargamos más
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreSets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Carga inicial o nueva búsqueda
  Future<void> _loadSets({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _sets.clear();
        _isLoading = true;
        _hasMore = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await apiService.getSetsByTheme(
        widget.theme.id,
        page: _currentPage,
        search: _currentSearch,
      );

      setState(() {
        _sets.addAll(response['sets'] as List<LegoSet>);
        _hasMore = response['hasMore'] as bool;
        _isLoading = false;
        _applySorting(); // Ordenamos lo que tenemos
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Cargar la siguiente página al hacer scroll
  Future<void> _loadMoreSets() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    try {
      final response = await apiService.getSetsByTheme(
        widget.theme.id,
        page: _currentPage,
        search: _currentSearch,
      );

      setState(() {
        _sets.addAll(response['sets'] as List<LegoSet>);
        _hasMore = response['hasMore'] as bool;
        _isLoadingMore = false;
        _applySorting();
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revertimos la página si falla
      });
    }
  }

  // Ejecutar búsqueda en el servidor
  void _runSearch(String keyword) {
    _currentSearch = keyword;
    _loadSets(resetPage: true);
  }

  // --- Mantenemos tu lógica de ordenación local de la lista que ya tenemos cargada ---
  void _applySorting() {
    if (_currentSort == 'name_asc') {
      _sets.sort((a, b) => a.name.compareTo(b.name));
    } else if (_currentSort == 'name_desc') {
      _sets.sort((a, b) => b.name.compareTo(a.name));
    } else if (_currentSort == 'year_desc') {
      _sets.sort((a, b) => b.year.compareTo(a.year));
    } else if (_currentSort == 'year_asc') {
      _sets.sort((a, b) => a.year.compareTo(b.year));
    } else if (_currentSort == 'pieces_desc') {
      _sets.sort((a, b) => b.numParts.compareTo(a.numParts));
    } else if (_currentSort == 'pieces_asc') {
      _sets.sort((a, b) => a.numParts.compareTo(b.numParts));
    }
  }

  String _getImageUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return '';
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const Text(
                'Ordenar por',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSortOption(
                'Nombre (A - Z)',
                'name_asc',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                'Nombre (Z - A)',
                'name_desc',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                'Año (Más recientes)',
                'year_desc',
                Icons.calendar_today,
              ),
              _buildSortOption(
                'Año (Más antiguos)',
                'year_asc',
                Icons.calendar_today,
              ),
              _buildSortOption(
                'Piezas (Mayor a menor)',
                'pieces_desc',
                Icons.extension,
              ),
              _buildSortOption(
                'Piezas (Menor a mayor)',
                'pieces_asc',
                Icons.extension,
              ),
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
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.orange)
          : null,
      onTap: () {
        setState(() {
          _currentSort = sortValue;
          _applySorting();
        });
        Navigator.pop(context);
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
        title: Text(
          widget.theme.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      // CAMBIO CLAVE: Búsqueda al darle a "Enter/Submit"
                      onSubmitted: (value) => _runSearch(value),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.orange,
                      decoration: InputDecoration(
                        hintText: 'Buscar set...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.orange,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _runSearch(
                                    '',
                                  ); // Refresca borrando la búsqueda
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.orange),
                    onPressed: _showSortBottomSheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Error: $_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_sets.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron sets',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController, // Añadimos el controlador de scroll aquí
      itemCount:
          _sets.length +
          (_hasMore
              ? 1
              : 0), // Añadimos 1 extra si hay más para mostrar el spinner final
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        // Si llegamos al último elemento extra y hay más, pintamos un spinner
        if (index == _sets.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final set = _sets[index];
        final finalImageUrl = _getImageUrl(set.imgUrl);

        return ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: finalImageUrl.isEmpty
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : CachedNetworkImage(
                    imageUrl: finalImageUrl,
                    memCacheWidth: 200,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                    fit: BoxFit.contain,
                  ),
          ),
          title: Text(
            set.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '#${set.setNum} | ${set.year} | ${set.numParts} piezas',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.orange),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SetDetailsScreen(legoSet: set),
              ),
            );
          },
        );
      },
    );
  }
} **/
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class SetsListScreen extends StatefulWidget {
  final LegoTheme theme;

  const SetsListScreen({super.key, required this.theme});

  @override
  State<SetsListScreen> createState() => _SetsListScreenState();
}

class _SetsListScreenState extends State<SetsListScreen> {
  final ApiService apiService = ApiService();

  List<LegoSet> _sets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  int _currentPage = 1;
  int _totalCount = 0;
  String? _nextPageUrl; // Nos avisa si quedan más sets por cargar

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSets(reset: true);
  }

  Future<void> _loadSets({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _sets.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await apiService.getSetsByTheme(
        widget.theme.id,
        page: _currentPage,
        search: _searchController.text,
      );

      setState(() {
        _sets.addAll(response['sets'] as List<LegoSet>);
        _totalCount = response['count'];
        _nextPageUrl = response['next']; // Si es null, ya no hay más páginas
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      debugPrint('Error cargando sets: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    // Al buscar, reiniciamos la lista para pedir desde la página 1
    _loadSets(reset: true);
  }

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(widget.theme.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 45,
              decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) => _runFilter(value),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.orange,
                decoration: InputDecoration(
                  // TEXTO DE AYUDA MEJORADO: Explica al usuario que puede usar el número también
                  hintText: 'Buscar nombre o número (ej: 42115-1)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
                        '$_totalCount SETS ENCONTRADOS',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _sets.isEmpty
                      ? const Center(child: Text('No se encontraron sets', style: TextStyle(color: Colors.white54)))
                      // USAMOS UN ÚNICO LISTVIEW PARA MÁXIMO RENDIMIENTO (Anti-diseño, estilo nativo)
                      : ListView.builder(
                          itemCount: _sets.length + (_nextPageUrl != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            
                            // Si estamos en el último elemento y hay página siguiente, mostramos el botón
                            if (index == _sets.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator(color: Colors.orange)
                                      : OutlinedButton.icon(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                          label: const Text('Cargar más sets', style: TextStyle(color: Colors.orange)),
                                          onPressed: () {
                                            _currentPage++;
                                            _loadSets();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.orange),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                        ),
                                ),
                              );
                            }

                            final legoSet = _sets[index];
                            
                            // DISEÑO DE LISTA (Imagen a la izquierda, info a la derecha)
                            return Card(
                              color: const Color(0xFF2A2A2A),
                              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8.0),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6.0),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.white, // Fondo blanco por si la foto es transparente
                                    child: CachedNetworkImage(
                                      imageUrl: _getImageUrl(legoSet.imgUrl),
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Padding(
                                        padding: EdgeInsets.all(15.0),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  legoSet.name, 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set: ${legoSet.setNum} • Año: ${legoSet.year}', 
                                        style: const TextStyle(color: Colors.grey, fontSize: 13)
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.extension, size: 14, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${legoSet.numParts} piezas', 
                                            style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: legoSet))
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}