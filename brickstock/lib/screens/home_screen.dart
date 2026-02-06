import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart'; // Para efectos de carga suaves
import '../services/api_service.dart';
import '../models/lego_set.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<List<LegoSet>> futureFeaturedSets;

  @override
  void initState() {
    super.initState();
    // TRUCO: Para la portada, cargamos un tema popular fijo (158 = Star Wars)
    // Así parece que son "Novedades" o "Destacados"
    futureFeaturedSets = apiService.getSetsByTheme(158);
  }

  @override
  Widget build(BuildContext context) {
    // Recordatorio: No usamos Scaffold aquí porque MainLayout ya nos da la estructura
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TÍTULO DEL DASHBOARD
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

          // 2. SECCIÓN DE DESTACADOS (API REAL)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DESTACADOS (Star Wars)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              // Pequeño botón de "Ver más" estético
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. CARRUSEL HORIZONTAL DE SETS
          Expanded(
            child: FutureBuilder<List<LegoSet>>(
              future: futureFeaturedSets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay sets destacados'));
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal, // Desplazamiento lateral
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final set = snapshot.data![index];
                    return _FeaturedSetCard(legoSet: set);
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

// --- WIDGET TARJETA DE SET (Diseño vertical) ---
class _FeaturedSetCard extends StatelessWidget {
  final LegoSet legoSet;

  const _FeaturedSetCard({required this.legoSet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, // Ancho fijo para cada tarjeta
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN DEL SET
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // FadeInImage hace que la imagen aparezca suavemente al cargar
                FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image:
                      legoSet.imgUrl ??
                      'https://cdn.rebrickable.com/media/sets/20006-1/233.jpg',
                  fit: BoxFit.cover,
                ),
                // Gradiente para que el texto se lea bien si lo ponemos encima
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

          // TEXTOS
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
                      // Número del Set (estilo técnico)
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

                  // Año y Piezas
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
                      const Icon(Icons.extension, size: 12, color: Colors.grey),
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
    );
  }
}
