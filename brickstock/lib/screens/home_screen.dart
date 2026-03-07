import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../models/lego_theme.dart';
import 'set_details_screen.dart';
import 'sets_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();

  // Controlador para las flechas de navegación
  final ScrollController _scrollController = ScrollController();

  //Future porque tardan los datos en llegar de internet
  Future<List<LegoSet>>? futureFeaturedSets;

  // Si es null, significa que estamos en modo "Mix Aleatorio"
  // HAY QUE DARLE UNA VUELTA A ESTO!!!
  LegoTheme? featuredTheme;

  @override
  void initState() {
    super.initState();
    _loadMixedFeaturedSets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Cagamos distintos sets de distintos temas
  Future<void> _loadMixedFeaturedSets() async {
    try {
      // Pedimos todos los temas a la API
      final themes = await apiService.getThemes();

      if (themes.isNotEmpty) {
        // Cada vez que entramos a themes mezclamos para que salga aleatorio
        themes.shuffle();
        // Cogemos 12 aunque vayamos a mostrar 10 ( por si hay algun fallo )
        final selectedThemes = themes.take(12).toList();

        // Aqui preparamos una lista (futures) para hacer una sola petición por cada tema seleccionado
        final futures = selectedThemes.map(
          (t) => apiService.getSetsByTheme(t.id),
        );
        // La peticion se hace aqui
        final results = await Future.wait(futures);

        // Recorremos los resultados y solo cogemos el primer set de cada tema
        final List<LegoSet> mixedList = [];
        for (var setList in results) {
          if (setList.isNotEmpty) {
            mixedList.add(setList.first);
          }
        }

        // Actualizamos la pantalla (limitado a 10)
        setState(() {
          featuredTheme = null; // !!! DARLE UNA VUELTA A ESTO !!! 
          futureFeaturedSets = Future.value(mixedList.take(10).toList());
        });
      }
    } catch (e) {
      debugPrint('Error cargando mix aleatorio: $e');
    }
  }

  // Función para mover el scroll con las flechas
  void _scrollList(double offset) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + offset, // Posicion actual + offset (220px en este caso)
        duration: const Duration(milliseconds: 300), // Duracion de la animacion
        curve: Curves.easeOut, // Animacion de rapida a lenta
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          const Text(
            'PANEL DE CONTROL',
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bienvenido de nuevo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 30),

          // 2. TÍTULO Y CONTROLES
          Row(
            children: [
              Expanded(
                child: Text(
                  // Si featuredTheme es null, mostramos título genérico
                  featuredTheme != null
                      ? 'DESTACADOS (${featuredTheme!.name})'
                      : 'DESTACADOS',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Flechas de navegación manual
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => _scrollList(-220),
                tooltip: "Anterior",
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
                onPressed: () => _scrollList(220),
                tooltip: "Siguiente",
              ),

              const SizedBox(width: 8),

              // Botón "Ver todos"
              // Solo se muestra si hay un tema específico seleccionado.
              // En el modo Mix lo ocultamos porque no hay "un catálogo" que ver.
              if (featuredTheme != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SetsListScreen(theme: featuredTheme!),
                      ),
                    );
                  },
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. CARRUSEL
          Expanded(
            child: futureFeaturedSets == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : FutureBuilder<List<LegoSet>>(
                    future: futureFeaturedSets,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay sets destacados'),
                        );
                      }

                      return ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _FeaturedSetCard(
                            legoSet: snapshot.data![index],
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// TARJETA DE SET
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  //Funcion necesaria para cargar las imagenes, usando proxy en Web para evitar CORS y la URL original en Móvil
  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return 'http://localhost:3000/api/lego/image-proxy?url=$encodedUrl';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { // al hacer click, nos movemos a la pantalla Details 
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetDetailsScreen(legoSet: legoSet),
          ),
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Stack( //Stack nos permite poner cosas encima de otras
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _getImageUrl(legoSet.imgUrl),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Textos
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${legoSet.setNum}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          legoSet.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${legoSet.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.extension,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${legoSet.numParts} pcs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
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
