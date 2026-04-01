import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import '../models/minifigure.dart';
import '../services/api_service.dart';
import '../models/lego_set.dart';
import '../screens/set_details_screen.dart';
import '../screens/minifig_details_screen.dart'; // <--- IMPORTANTE: Importamos la nueva pantalla

class MinifiguresBottomSheet extends StatefulWidget {
  final String setNum;

  const MinifiguresBottomSheet({super.key, required this.setNum});

  @override
  State<MinifiguresBottomSheet> createState() => _MinifiguresBottomSheetState();
}

class _MinifiguresBottomSheetState extends State<MinifiguresBottomSheet> {
  // TFG: Esta es la clave del estado local. 
  // Si es null, mostramos la lista. Si tiene una figura, mostramos sus detalles.
  Minifigure? _selectedMinifigure;

  // Reutilizamos tu lógica de proxy para que las imágenes carguen en Flutter Web sin error CORS
  String _getImageUrl(String originalUrl) {
    if (kIsWeb && originalUrl.isNotEmpty) {
      return ApiService().getProxyUrl(originalUrl);
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.7, // Ocupa el 70% de la pantalla
      child: Column(
        children: [
          // CABECERA DEL BOTTOM SHEET
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Botón de retroceso (solo aparece si estamos viendo un detalle)
                if (_selectedMinifigure != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedMinifigure = null; // Volvemos a la lista
                      });
                    },
                  )
                else
                  const SizedBox(width: 48), // Espaciador para centrar el título

                Expanded(
                  child: Text(
                    _selectedMinifigure == null 
                        ? 'Minifiguras del Set' 
                        : 'Detalles de la Figura',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                
                // === NUEVO: BOTÓN DE VÍNCULO EXTERNO A PANTALLA COMPLETA ===
                if (_selectedMinifigure != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.orange),
                    tooltip: 'Ver Ficha Completa',
                    onPressed: () {
                      final fig = _selectedMinifigure!;
                      // 1. Cerramos el modal actual para limpiar la pila de navegación
                      Navigator.pop(context);
                      // 2. Navegamos a la pantalla de detalles de la minifigura
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MinifigDetailsScreen(minifigure: fig),
                        ),
                      );
                    },
                  ),
                // =============================================================

                // Botón para cerrar el modal
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // CONTENIDO DINÁMICO (Lista o Detalle)
          Expanded(
            child: _selectedMinifigure == null 
                ? _buildMinifiguresList() 
                : _buildMinifigureDetails(),
          ),
        ],
      ),
    );
  }

  // VISTA 1: LA LISTA
  Widget _buildMinifiguresList() {
    return FutureBuilder<List<Minifigure>>(
      future: ApiService().getSetMinifigures(widget.setNum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Este set no contiene minifiguras.'));
        }

        final minifigs = snapshot.data!;
        return ListView.builder(
          itemCount: minifigs.length,
          itemBuilder: (context, index) {
            final fig = minifigs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: fig.imageUrl.isNotEmpty
                    ? NetworkImage(_getImageUrl(fig.imageUrl))
                    : null,
                backgroundColor: Colors.transparent,
                child: fig.imageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(fig.name),
              subtitle: Text(fig.figNum),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Al pulsar, actualizamos el estado para mostrar el detalle local en el sheet
                setState(() {
                  _selectedMinifigure = fig;
                });
              },
            );
          },
        );
      },
    );
  }

  // VISTA 2: EL DETALLE LOCAL
  Widget _buildMinifigureDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_selectedMinifigure!.imageUrl.isNotEmpty)
            Image.network(
              _getImageUrl(_selectedMinifigure!.imageUrl),
              height: 200,
              fit: BoxFit.contain,
            )
          else
            const Icon(Icons.person, size: 100, color: Colors.grey),
          
          const SizedBox(height: 24),
          
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Nombre', style: TextStyle(color: Colors.white70)),
                    subtitle: Text(_selectedMinifigure!.name, style: const TextStyle(color: Colors.white)),
                    leading: const Icon(Icons.badge, color: Colors.orange),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    title: const Text('Número de Identificación', style: TextStyle(color: Colors.white70)),
                    subtitle: Text(_selectedMinifigure!.figNum, style: const TextStyle(color: Colors.white)),
                    leading: const Icon(Icons.tag, color: Colors.orange),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    title: const Text('Cantidad en este set', style: TextStyle(color: Colors.white70)),
                    subtitle: Text('${_selectedMinifigure!.quantity} unidades', style: const TextStyle(color: Colors.white)),
                    leading: const Icon(Icons.inventory_2, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'También aparece en:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Colors.white10),
          FutureBuilder<List<LegoSet>>(
            future: ApiService().getMinifigSets(_selectedMinifigure!.figNum),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No hay datos disponibles.', style: TextStyle(color: Colors.white54));
              }

              final allSets = snapshot.data!;
              
              // Filtramos para NO mostrar el set en el que ya estamos
              final otherSets = allSets.where((s) => s.setNum != widget.setNum).toList();

              if (otherSets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '🌟 ¡Esta figura es exclusiva de este set!',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(),
                itemCount: otherSets.length,
                itemBuilder: (context, index) {
                  final setItem = otherSets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero, 
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: setItem.imgUrl.isNotEmpty
                          ? Image.network(_getImageUrl(setItem.imgUrl), fit: BoxFit.contain)
                          : const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                    title: Text(setItem.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(setItem.setNum, style: const TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetDetailsScreen(legoSet: setItem),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}