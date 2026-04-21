import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import '../models/minifigure.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';
import 'minifig_details_screen.dart';

enum SearchMode { sets, minifigs }

class ElementsListScreen extends StatefulWidget {
  final LegoTheme? theme;
  final String? customTitle;

  const ElementsListScreen({super.key, this.theme, this.customTitle});

  @override
  State<ElementsListScreen> createState() => _ElementsListScreenState();
}

class _ElementsListScreenState extends State<ElementsListScreen> {
  final ApiService apiService = ApiService();

  // ESTADO DE SETS
  List<LegoSet> _sets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _nextPageUrl;

  // ESTADO DE MINIFIGURAS
  SearchMode _searchMode = SearchMode.sets;
  List<Minifigure> _minifigs = [];
  bool _isLoadingMinifigs = false;
  bool _isLoadingMoreMinifigs = false;
  int _minifigsPage = 1;
  int _totalMinifigsCount = 0;
  String? _nextMinifigsPageUrl;

  final TextEditingController _searchController = TextEditingController();

  // Variable auxiliar para saber si estamos en Búsqueda Global o en un Tema
  bool get _isGlobalSearch => widget.theme == null;

  @override
  void initState() {
    super.initState();
    _loadSets(reset: true);
  }

  Future<void> _loadSets({bool reset = false}) async {
    if (_isGlobalSearch && _searchController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _sets.clear();
        _totalCount = 0;
      });
      return;
    }

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
      final response = !_isGlobalSearch
          ? await apiService.getSetsByTheme(
              widget.theme!.id,
              page: _currentPage,
              search: _searchController.text,
            )
          : await apiService.getAllSets(
              page: _currentPage,
              search: _searchController.text,
            );

      setState(() {
        _sets.addAll(response['sets'] as List<LegoSet>);
        _totalCount = response['count'];
        _nextPageUrl = response['next'];
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

  Future<void> _loadMinifigs({bool reset = false}) async {
    // Si estamos en un tema, no intentamos cargar minifiguras
    if (!_isGlobalSearch) return;

    if (_isGlobalSearch && _searchController.text.trim().isEmpty) {
      setState(() {
        _isLoadingMinifigs = false;
        _isLoadingMoreMinifigs = false;
        _minifigs.clear();
        _totalMinifigsCount = 0;
      });
      return;
    }

    if (reset) {
      setState(() {
        _minifigsPage = 1;
        _isLoadingMinifigs = true;
        _minifigs.clear();
      });
    } else {
      setState(() => _isLoadingMoreMinifigs = true);
    }

    try {
      final response = await apiService.getAllMinifigs(
        page: _minifigsPage,
        search: _searchController.text,
      );

      setState(() {
        _minifigs.addAll(response['minifigs']);
        _totalMinifigsCount = response['count'];
        _nextMinifigsPageUrl = response['next'];
        _isLoadingMinifigs = false;
        _isLoadingMoreMinifigs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMinifigs = false;
        _isLoadingMoreMinifigs = false;
      });
      debugPrint('Error cargando minifiguras: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    if (_searchMode == SearchMode.sets) {
      _loadSets(reset: true);
    } else {
      _loadMinifigs(reset: true);
    }
  }

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle =
        widget.theme?.name ?? widget.customTitle ?? 'Buscar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle
        ),
        leading: !_isGlobalSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.orange),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: PreferredSize(
          // Ajustamos el alto dinámicamente. Si es global, caben las pestañas. Si es tema, solo el buscador.
          preferredSize: Size.fromHeight(_isGlobalSearch ? 115.0 : 60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _runFilter(value),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.orange,
                    decoration: InputDecoration(
                      hintText:
                          _searchMode == SearchMode.sets || !_isGlobalSearch
                          ? 'Buscar set por nombre o número...'
                          : 'Buscar minifigura (ej: luke)...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
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
                                _runFilter('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // Solo mostramos el toggle si estamos en Búsqueda Global
                if (_isGlobalSearch) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<SearchMode>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.white10),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: SearchMode.sets,
                        label: Text('Sets'),
                        icon: Icon(Icons.inventory_2),
                      ),
                      ButtonSegment(
                        value: SearchMode.minifigs,
                        label: Text('Minifiguras'),
                        icon: Icon(Icons.smart_toy),
                      ),
                    ],
                    selected: {_searchMode},
                    onSelectionChanged: (Set<SearchMode> newSelection) {
                      setState(() {
                        _searchMode = newSelection.first;
                      });

                      if (_searchMode == SearchMode.sets && _sets.isEmpty) {
                        _loadSets(reset: true);
                      } else if (_searchMode == SearchMode.minifigs &&
                          _minifigs.isEmpty) {
                        _loadMinifigs(reset: true);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      //Si estamos dentro de un tema, FORZAMOS a que renderice la lista de Sets
      body: (!_isGlobalSearch || _searchMode == SearchMode.sets)
          ? _buildSetsList()
          : _buildMinifigsList(),
    );
  }

  // VISTA LISTA DE SETS
  Widget _buildSetsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$_totalCount SETS ENCONTRADOS',
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
        Expanded(
          child: _sets.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron sets',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Parámetros de seguridad para el Grid
                    const double maxColumnWidth = 450.0;
                    const double minItemHeight = 125.0; 

                    // Cálculo matemático dinámico
                    int columns = (constraints.maxWidth / maxColumnWidth).ceil();
                    if (columns < 1) columns = 1;
                    
                    double itemWidth = constraints.maxWidth / columns;
                    double dynamicAspectRatio = itemWidth / minItemHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: dynamicAspectRatio,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: _sets.length + (_nextPageUrl != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _sets.length) {
                          return Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator(color: Colors.orange)
                                : OutlinedButton.icon(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                    label: const Text('Cargar más', style: TextStyle(color: Colors.orange)),
                                    onPressed: () {
                                      _currentPage++;
                                      _loadSets();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                  ),
                          );
                        }

                        final legoSet = _sets[index];
                        return Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile( // Sin el Center() para usar todo el alto de la Card
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.white,
                                child: CachedNetworkImage(
                                  imageUrl: _getImageUrl(legoSet.imgUrl),
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              legoSet.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Set: ${legoSet.setNum} • Año: ${legoSet.year}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.extension, size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${legoSet.numParts} piezas',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => SetDetailsScreen(legoSet: legoSet),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // VISTA LISTA DE MINIFIGURAS
  Widget _buildMinifigsList() {
    if (_isLoadingMinifigs) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$_totalMinifigsCount MINIFIGURAS ENCONTRADAS',
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
        Expanded(
          child: _minifigs.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron minifiguras',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const double maxColumnWidth = 450.0;
                    const double minItemHeight = 125.0;

                    int columns = (constraints.maxWidth / maxColumnWidth).ceil();
                    if (columns < 1) columns = 1;

                    double itemWidth = constraints.maxWidth / columns;
                    double dynamicAspectRatio = itemWidth / minItemHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: dynamicAspectRatio,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: _minifigs.length + (_nextMinifigsPageUrl != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _minifigs.length) {
                          return Center(
                            child: _isLoadingMoreMinifigs
                                ? const CircularProgressIndicator(color: Colors.orange)
                                : OutlinedButton.icon(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                    label: const Text('Cargar más', style: TextStyle(color: Colors.orange)),
                                    onPressed: () {
                                      _minifigsPage++;
                                      _loadMinifigs();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                  ),
                          );
                        }

                        final fig = _minifigs[index];
                        return Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.white,
                                child: CachedNetworkImage(
                                  imageUrl: _getImageUrl(fig.imageUrl),
                                  fit: BoxFit.contain,
                                  memCacheWidth: 200,
                                  placeholder: (context, url) => const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.face, color: Colors.black),
                                ),
                              ),
                            ),
                            title: Text(
                              fig.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: ${fig.figNum}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.extension, size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${fig.numParts} piezas',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => MinifigDetailsScreen(minifigure: fig),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMinifigDialog(Minifigure fig) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Añadir a Colección',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Quieres añadir a ${fig.name} como pieza suelta a tu cartera?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final res = await apiService.addMinifigToCollection(fig.figNum);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message']),
                  backgroundColor: res['success'] ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
