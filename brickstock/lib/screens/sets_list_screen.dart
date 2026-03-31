import 'package:flutter/material.dart';
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
}