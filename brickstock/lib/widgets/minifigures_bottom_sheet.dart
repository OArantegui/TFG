import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import '../models/minifigure.dart';
import '../services/api_service.dart';

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
          return const Center(child: CircularProgressIndicator());
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
                child: fig.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                backgroundColor: Colors.transparent,
              ),
              title: Text(fig.name),
              subtitle: Text(fig.figNum),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TFG: Al pulsar, actualizamos el estado para mostrar el detalle
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

  // VISTA 2: EL DETALLE
  Widget _buildMinifigureDetails() {
    // Usamos componentes puros de Material (Anti-Diseño)
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Nombre'),
                    subtitle: Text(_selectedMinifigure!.name),
                    leading: const Icon(Icons.badge),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Número de Identificación'),
                    subtitle: Text(_selectedMinifigure!.figNum),
                    leading: const Icon(Icons.tag),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Cantidad en este set'),
                    subtitle: Text('${_selectedMinifigure!.quantity} unidades'),
                    leading: const Icon(Icons.inventory_2),
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