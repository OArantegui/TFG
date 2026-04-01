/*import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import '../services/api_service.dart';
import 'set_details_screen.dart';

class SetsListScreen extends StatefulWidget {
  // TFG: Convertimos 'theme' en opcional (nullable)
  final LegoTheme? theme;
  
  // TFG: Añadimos un título opcional para cuando no hay tema
  final String? customTitle;

  const SetsListScreen({super.key, this.theme, this.customTitle});

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
  String? _nextPageUrl; 

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSets(reset: true);
  }

  Future<void> _loadSets({bool reset = false}) async {
    // TFG: CORTAFUEGOS (Lazy Fetching)
    // Si NO hay tema (Búsqueda Global) y el buscador está vacío, NO llamamos a la API.
    if (widget.theme == null && _searchController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _sets.clear();
        _totalCount = 0;
      });
      return; // Salimos de la función inmediatamente
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
      final response = widget.theme != null 
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

  void _runFilter(String enteredKeyword) {
    _loadSets(reset: true);
  }

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    // TFG: Determinamos el título de la AppBar
    final String appBarTitle = widget.theme?.name ?? widget.customTitle ?? 'Buscar Sets';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // TFG: Solo mostramos flecha de volver si NO estamos en la pestaña principal
        leading: widget.theme != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.orange),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
                      : ListView.builder(
                          itemCount: _sets.length + (_nextPageUrl != null ? 1 : 0),
                          itemBuilder: (context, index) {
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
                                    color: Colors.white, 
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
}*/
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import '../models/minifigure.dart'; // <-- TFG: Importamos el modelo
import '../services/api_service.dart';
import 'set_details_screen.dart';

// TFG: Definimos los tipos de búsqueda
enum SearchMode { sets, minifigs }

class SetsListScreen extends StatefulWidget {
  final LegoTheme? theme;
  final String? customTitle;

  const SetsListScreen({super.key, this.theme, this.customTitle});

  @override
  State<SetsListScreen> createState() => _SetsListScreenState();
}

class _SetsListScreenState extends State<SetsListScreen> {
  final ApiService apiService = ApiService();

  // --- ESTADO DE SETS (Original) ---
  List<LegoSet> _sets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _nextPageUrl; 

  // --- ESTADO DE MINIFIGURAS (Nuevo) ---
  SearchMode _searchMode = SearchMode.sets; // Modo por defecto
  List<Minifigure> _minifigs = [];
  bool _isLoadingMinifigs = false;
  bool _isLoadingMoreMinifigs = false;
  int _minifigsPage = 1;
  int _totalMinifigsCount = 0;
  String? _nextMinifigsPageUrl;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSets(reset: true);
    // Nota: No cargamos minifiguras hasta que el usuario toque el botón
  }

  // ===============================================
  // LÓGICA DE DATOS: SETS
  // ===============================================
  Future<void> _loadSets({bool reset = false}) async {
    if (widget.theme == null && _searchController.text.trim().isEmpty) {
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
      final response = widget.theme != null 
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

  // ===============================================
  // LÓGICA DE DATOS: MINIFIGURAS
  // ===============================================
  Future<void> _loadMinifigs({bool reset = false}) async {
    // Si estamos en un tema y queremos buscar minifiguras, 
    // la búsqueda de minifiguras se vuelve global (ya que la API de Rebrickable no filtra minifigs por tema fácilmente)
    if (widget.theme == null && _searchController.text.trim().isEmpty) {
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

  // ===============================================
  // EVENTOS DE UI
  // ===============================================
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
    final String appBarTitle = widget.theme?.name ?? widget.customTitle ?? 'Buscar Sets';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: widget.theme != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.orange),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: PreferredSize(
          // TFG: Aumentamos el tamaño para meter el SegmentedButton
          preferredSize: const Size.fromHeight(115.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // BUSCADOR (Original)
                Container(
                  height: 45,
                  decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _runFilter(value),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.orange,
                    decoration: InputDecoration(
                      hintText: _searchMode == SearchMode.sets 
                          ? 'Buscar nombre o número (ej: 42115-1)...'
                          : 'Buscar minifigura (ej: luke, fig-001)...',
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
                const SizedBox(height: 12),
                
                // TFG: TOGGLE NATIVO MATERIAL 3
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
                      icon: Icon(Icons.person_pin),
                    ),
                  ],
                  selected: {_searchMode},
                  onSelectionChanged: (Set<SearchMode> newSelection) {
                    setState(() {
                      _searchMode = newSelection.first;
                    });
                    
                    // Si cambiamos a Sets y está vacío, cargamos. Igual con Minifiguras.
                    if (_searchMode == SearchMode.sets && _sets.isEmpty) {
                      _loadSets(reset: true);
                    } else if (_searchMode == SearchMode.minifigs && _minifigs.isEmpty) {
                      _loadMinifigs(reset: true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      // TFG: Selector de vista según el estado
      body: _searchMode == SearchMode.sets ? _buildSetsList() : _buildMinifigsList(),
    );
  }

  // ===============================================
  // VISTA 1: LISTA DE SETS (Tu código original intacto)
  // ===============================================
  Widget _buildSetsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.orange));
    
    return Column(
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
              : ListView.builder(
                  itemCount: _sets.length + (_nextPageUrl != null ? 1 : 0),
                  itemBuilder: (context, index) {
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
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: Container(
                            width: 70, height: 70, color: Colors.white, 
                            child: CachedNetworkImage(
                              imageUrl: _getImageUrl(legoSet.imgUrl),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Padding(padding: EdgeInsets.all(15.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        title: Text(legoSet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set: ${legoSet.setNum} • Año: ${legoSet.year}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.extension, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text('${legoSet.numParts} piezas', style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: legoSet)));
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===============================================
  // VISTA 2: LISTA DE MINIFIGURAS (Clonando tu estilo)
  // ===============================================
  Widget _buildMinifigsList() {
    if (_isLoadingMinifigs) return const Center(child: CircularProgressIndicator(color: Colors.orange));
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '$_totalMinifigsCount MINIFIGURAS ENCONTRADAS',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        Expanded(
          child: _minifigs.isEmpty
              ? const Center(child: Text('No se encontraron minifiguras', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _minifigs.length + (_nextMinifigsPageUrl != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _minifigs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: _isLoadingMoreMinifigs
                              ? const CircularProgressIndicator(color: Colors.orange)
                              : OutlinedButton.icon(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                  label: const Text('Cargar más minifiguras', style: TextStyle(color: Colors.orange)),
                                  onPressed: () {
                                    _minifigsPage++;
                                    _loadMinifigs();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.orange),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                        ),
                      );
                    }

                    final fig = _minifigs[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: Container(
                            width: 70, height: 70, color: Colors.white, 
                            child: CachedNetworkImage(
                              imageUrl: _getImageUrl(fig.imageUrl),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Padding(padding: EdgeInsets.all(15.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                              errorWidget: (context, url, error) => const Icon(Icons.face, color: Colors.black),
                            ),
                          ),
                        ),
                        title: Text(fig.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${fig.figNum}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.extension, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text('${fig.numParts} piezas', style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.orange),
                          tooltip: "Añadir a colección",
                          onPressed: () => _showAddMinifigDialog(fig),
                        ),
                        // onTap: () {
                        //   Aquí navegaremos a la pantalla de detalles de la minifigura en el siguiente paso
                        // },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===============================================
  // DIÁLOGO PARA AÑADIR A COLECCIÓN DIRECTAMENTE
  // ===============================================
  void _showAddMinifigDialog(Minifigure fig) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Añadir a Colección', style: TextStyle(color: Colors.white)),
        content: Text('¿Quieres añadir a ${fig.name} como pieza suelta a tu cartera?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final res = await apiService.addMinifigToCollection(fig.figNum);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red),
              );
            }, 
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}