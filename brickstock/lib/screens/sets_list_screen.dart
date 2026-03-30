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
        _nextPageUrl = response['next']; // Si es null, el botón "Ver más" desaparecerá
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
    // Busca en la API forzando recarga desde la página 1
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
                  hintText: 'Buscar set en ${widget.theme.name} (Intro)...',
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
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16,
                              ),
                              itemCount: _sets.length,
                              itemBuilder: (context, index) {
                                final legoSet = _sets[index];
                                return _SetCard(legoSet: legoSet, getImageUrl: _getImageUrl);
                              },
                            ),
                            
                            // BOTÓN DE CARGAR MÁS (Solo si Rebrickable dice que hay más páginas)
                            if (_nextPageUrl != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator(color: Colors.orange)
                                      : OutlinedButton.icon(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                          label: const Text('Ver más sets', style: TextStyle(color: Colors.orange)),
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
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

// Widget Tarjeta de Set refactorizado para limpieza de código
class _SetCard extends StatelessWidget {
  final LegoSet legoSet;
  final Function(String) getImageUrl;

  const _SetCard({required this.legoSet, required this.getImageUrl});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailsScreen(legoSet: legoSet))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: getImageUrl(legoSet.imgUrl),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: Text('#${legoSet.setNum}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const SizedBox(height: 4),
                        Text(legoSet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [const Icon(Icons.calendar_today, size: 10, color: Colors.grey), const SizedBox(width: 4), Text('${legoSet.year}', style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                        Row(children: [const Icon(Icons.extension, size: 10, color: Colors.grey), const SizedBox(width: 4), Text('${legoSet.numParts} pts', style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}