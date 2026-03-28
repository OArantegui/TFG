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

  // VARIABLE PARA EL ESTADO DE ORDENACIÓN
  String _currentSort = 'name_asc';

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final sets = await apiService.getSetsByTheme(widget.theme.id);
      setState(() {
        _allSets = sets;
        _filteredSets = sets;
        _isLoading = false;
        _applySorting(); // Aplicar ordenación por defecto al cargar
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error cargando sets: $e');
    }
  }

  // Lógica de búsqueda
  void _runFilter(String enteredKeyword) {
    List<LegoSet> results = [];
    if (enteredKeyword.isEmpty) {
      results = List.from(_allSets);
    } else {
      results = _allSets.where((set) {
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
      _applySorting(); // Volver a ordenar después de filtrar
    });
  }

  // Lógica de ordenación
  void _applySorting() {
    if (_currentSort == 'name_asc') {
      _filteredSets.sort((a, b) => a.name.compareTo(b.name));
    } else if (_currentSort == 'name_desc') {
      _filteredSets.sort((a, b) => b.name.compareTo(a.name));
    } else if (_currentSort == 'year_desc') {
      _filteredSets.sort((a, b) => b.year.compareTo(a.year));
    } else if (_currentSort == 'year_asc') {
      _filteredSets.sort((a, b) => a.year.compareTo(b.year));
    } else if (_currentSort == 'pieces_desc') {
      _filteredSets.sort((a, b) => b.numParts.compareTo(a.numParts));
    } else if (_currentSort == 'pieces_asc') {
      _filteredSets.sort((a, b) => a.numParts.compareTo(b.numParts));
    }
  }

  // --- REUTILIZADA ---
  String _getImageUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return '';
    if (kIsWeb) return apiService.getProxyUrl(originalUrl);
    return originalUrl;
  }

  // --- MENÚ INFERIOR DE ORDENACIÓN (ESTÉTICA APP) ---
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors
          .transparent, // Transparente para usar nuestro propio diseño curvo
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Fondo oscuro de la app
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
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

  // Widget personalizado para cada opción del menú
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
        Navigator.pop(context); // Cerrar el menú
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
                // Barra de búsqueda ampliada
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
                      onChanged: (value) => _runFilter(value),
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
                                  _runFilter('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de filtros guay
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
          'No se encontraron sets',
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
}
