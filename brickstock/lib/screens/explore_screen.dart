import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- IMPORTANTE: Igual que en Home
import 'package:flutter/foundation.dart'; // <--- IMPORTANTE: Para kIsWeb
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

  // VARIABLES PARA EL BUSCADOR
  List<LegoTheme> _allThemes = [];
  List<LegoTheme> _filteredThemes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error cargando temas: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    List<LegoTheme> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allThemes;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Container(
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
            decoration: const InputDecoration(
              hintText: 'Buscar colección (ej. Star Wars)...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.orange),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            return _ThemeCard(theme: theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// --- TARJETA CON LA LÓGICA DE TU COMPAÑERO (CachedNetworkImage + Proxy) ---
class _ThemeCard extends StatefulWidget {
  final LegoTheme theme;

  const _ThemeCard({required this.theme});

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

  // ESTA ES LA FUNCIÓN CLAVE QUE USA TU COMPAÑERO EN LAS OTRAS PANTALLAS
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Si es Web -> Usamos el Proxy del Backend para saltar CORS
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    // Si es App -> Directo
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
            // 1. IMAGEN DE FONDO (USANDO CachedNetworkImage)
            Positioned.fill(
              child: FutureBuilder<String?>(
                future: _coverImageFuture,
                builder: (context, snapshot) {
                  // Si no hay dato o falla, ponemos imagen por defecto
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Image.network(
                      'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5),
                      colorBlendMode: BlendMode.darken,
                    );
                  }

                  // Si hay dato, aplicamos la lógica de "Otras pantallas"
                  final rawUrl = snapshot.data!;
                  final finalUrl = _getImageUrl(
                    rawUrl,
                  ); // <--- Lógica del Proxy

                  return CachedNetworkImage(
                    imageUrl: finalUrl,
                    fit: BoxFit.cover,
                    // Aplicamos el efecto oscuro para que se lea el texto
                    color: Colors.black.withOpacity(0.5),
                    colorBlendMode: BlendMode.darken,
                    // Mientras carga...
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    // Si falla...
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

            // 2. DECORACIÓN NARANJA
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

            // 3. TEXTO DEL TEMA
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
