import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../providers/home_provider.dart';
import '../widgets/nav_card.dart';
import 'set_details_screen.dart';
import 'elements_list_screen.dart';
import '../providers/user_provider.dart';
import 'scanner_screen.dart';

// StatelessWidget porque el estado lo maneja el HomeProvider
class HomeScreen extends StatelessWidget {
  // Recibimos la función de navegación desde MainLayout
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final userProvider = context.watch<UserProvider>();

    final screenWidth = MediaQuery.of(context).size.width;
    int navColumns = screenWidth > 800 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: Colors.transparent, // Mantiene el fondo oscuro
      // BOTÓN FLOTANTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        icon: SvgPicture.asset(
          'assets/icons/barcode_scan.svg',
          width: 24, // Tamaño estándar de un icono
          height: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        label: const Text(
          'Escanear Set',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Lo centra abajo

      body: RefreshIndicator(
        onRefresh: () =>
            context.read<HomeProvider>().refresh(), // Llama al nuevo método
        color: Colors.orange,
        child: CustomScrollView(
          slivers: [
            // CABECERA DINÁMICA: Desaparece al bajar, aparece al subir
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xFF1E1E1E),
              elevation: 0,
              title: const Text(
                'BRICKSTOCK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 1.2,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => onNavigate(5), // Perfil
                    child: Center(
                      child: CircleAvatar(
                        radius: 16, // Tamaño para que encaje bien en la AppBar
                        backgroundImage: AssetImage(
                          userProvider.avatar,
                        ), // Usamos la variable recibida
                        backgroundColor: const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // CONTENIDO PRINCIPAL
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Inicio',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // BOTONES DE NAVEGACIÓN
                  GridView.count(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // El scroll lo maneja el CustomScrollView
                    crossAxisCount: navColumns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      NavCard(
                        title: 'Buscar',
                        icon: Icons.search,
                        onTap: () => onNavigate(1), // Índice 1: Buscar
                      ),
                      NavCard(
                        title: 'Temas',
                        icon: Icons.list_alt,
                        onTap: () => onNavigate(2), // Índice 2: Temas
                      ),
                      NavCard(
                        title: 'Colección',
                        icon: Icons.shelves,
                        onTap: () => onNavigate(3), // Índice 3: Colección
                      ),
                      NavCard(
                        title: 'Deseados',
                        icon: Icons.favorite_border,
                        onTap: () => onNavigate(4), // Índice 4: Deseados
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // CABECERA DE NOVEDADES
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NOVEDADES RECOMENDADAS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                ]),
              ),
            ),

            // CARRUSEL DE DESTACADOS INTEGRADO EN SLIVER
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250, // Altura fija para el carrusel horizontal
                child: _buildCarouselContent(provider),
              ),
            ),

            // Espacio extra al final para que no se pegue al borde inferior
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // Lógica del carrusel novedades
  Widget _buildCarouselContent(HomeProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (provider.errorMessage != null) {
      return const Center(
        child: Text(
          'Error al cargar recomendaciones',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    // Usamos featuredSets
    if (provider.featuredSets.isEmpty) {
      return const Center(
        child: Text(
          'No hay recomendaciones disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: provider.featuredSets.length, // Usamos featuredSets
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return _FeaturedSetCard(
          legoSet: provider.featuredSets[index],
        ); // Usamos featuredSets
      },
    );
  }
}

// TARJETA DE SET DESTACADO
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  String _getImageUrl(String originalUrl) {
    if (kIsWeb) {
      return ApiService().getProxyUrl(originalUrl);
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetDetailsScreen(legoSet: legoSet),
          ),
        );
      },
      child: Container(
        width:
            180, // Ligeramente ajustado para que queden mejor en móviles pequeños
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
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
                            Colors.black.withOpacity(0.8),
                          ],
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
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Expanded(
                      child: Text(
                        legoSet.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          '${legoSet.numParts}',
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
