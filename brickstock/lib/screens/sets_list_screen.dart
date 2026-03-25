import 'package:flutter/material.dart';
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

  List<LegoSet> _allSets = [];
  List<LegoSet> _filteredSets = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  // Cargar los sets una sola vez al inicio
  Future<void> _loadSets() async {
    try {
      final sets = await apiService.getSetsByTheme(widget.theme.id);
      setState(() {
        _allSets = sets;
        _filteredSets = sets; // Al principio, mostramos todos
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error cargando sets: $e');
    }
  }

  // Función que filtra la lista conforme el usuario escribe
  void _runFilter(String enteredKeyword) {
    List<LegoSet> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allSets;
    } else {
      results = _allSets.where((set) {
        // Permite buscar por el nombre del set o por su número
        final nameMatches = set.name.toLowerCase().contains(
          enteredKeyword.toLowerCase(),
        );
        final numberMatches = set.setNum.toLowerCase().contains(
          enteredKeyword.toLowerCase(),
        );
        return nameMatches || numberMatches;
      }).toList();
    }

    setState(() {
      _filteredSets = results;
    });
  }

  // --- REUTILIZADA ---
  String _getImageUrl(String? originalUrl) {
    // 1. Si no hay imagen, devolvemos una cadena vacía
    if (originalUrl == null || originalUrl.isEmpty) {
      return '';
    }

    // 2. Si es Web, usamos la función centralizada del ApiService (Proxy)
    if (kIsWeb) {
      return apiService.getProxyUrl(originalUrl);
    }

    // 3. Si es Móvil, usamos la original
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          widget.theme.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        // Agregamos la barra de búsqueda en la parte inferior del AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _runFilter(value),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.orange,
                decoration: InputDecoration(
                  hintText: 'Buscar en ${widget.theme.name}...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  // Botón para limpiar la búsqueda
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
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // Separamos el body en una función para que el build quede más limpio
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

    if (_allSets.isEmpty) {
      return const Center(
        child: Text(
          'No hay sets en esta colección',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (_filteredSets.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron sets con esa búsqueda',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredSets.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final set = _filteredSets[index];
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
                    errorWidget: (context, url, error) {
                      return const Icon(Icons.broken_image, color: Colors.grey);
                    },
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
}
