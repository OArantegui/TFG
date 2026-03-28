import 'package:flutter/material.dart';
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

  List<LegoTheme> _allThemes = [];
  List<LegoTheme> _filteredThemes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  String _currentSort = 'name_asc';

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    try {
      final themes = await apiService.getThemes();
      setState(() {
        _allThemes = themes;
        _filteredThemes = themes;
        _isLoading = false;
        _applySorting();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando temas: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    List<LegoTheme> results = [];
    if (enteredKeyword.isEmpty) {
      results = List.from(_allThemes);
    } else {
      results = _allThemes
          .where(
            (theme) =>
                theme.name.toLowerCase().contains(enteredKeyword.toLowerCase()),
          )
          .toList();
    }
    setState(() {
      _filteredThemes = results;
      _applySorting();
    });
  }

  void _applySorting() {
    if (_currentSort == 'name_asc') {
      _filteredThemes.sort((a, b) => a.name.compareTo(b.name));
    } else if (_currentSort == 'name_desc') {
      _filteredThemes.sort((a, b) => b.name.compareTo(a.name));
    } else if (_currentSort == 'id_desc') {
      _filteredThemes.sort((a, b) => b.id.compareTo(a.id));
    } else if (_currentSort == 'id_asc') {
      _filteredThemes.sort((a, b) => a.id.compareTo(b.id));
    }
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
                'Ordenar colecciones por',
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
        title: const Text(
          'Catálogos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      onChanged: (value) => _runFilter(value),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.orange,
                      decoration: InputDecoration(
                        hintText: 'Buscar colección (ej. Star Wars)...',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
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
                                crossAxisCount: 2,
                                childAspectRatio: 1.1,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _filteredThemes.length,
                          itemBuilder: (context, index) {
                            final theme = _filteredThemes[index];
                            return _ThemeCard(
                              // AQUI ESTÁ LA CLAVE MÁGICA PARA LAS IMÁGENES
                              key: ValueKey(theme.id),
                              theme: theme,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final LegoTheme theme;

  // AQUI TAMBIÉN HEMOS AÑADIDO super.key
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
    if (kIsWeb) {
      return apiService.getProxyUrl(originalUrl);
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetsListScreen(theme: widget.theme),
          ),
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
            Positioned.fill(
              child: FutureBuilder<String?>(
                future: _coverImageFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Image.network(
                      'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    );
                  }

                  final rawUrl = snapshot.data!;
                  final finalUrl = _getImageUrl(rawUrl);

                  return CachedNetworkImage(
                    imageUrl: finalUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.5),
                    colorBlendMode: BlendMode.darken,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.network(
                      'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    ),
                  );
                },
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    widget.theme.name.toUpperCase(),
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
