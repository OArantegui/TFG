import 'package:flutter/material.dart';
import 'history_chart_widget.dart'; // Importamos el nuevo widget puro

class MarketDataWidget extends StatelessWidget {
  final String setNum;
  final Future<Map<String, dynamic>?> marketDataFuture;
  
  final bool showCards; 
  final bool showTitle;
  final bool showButton; // NUEVO: Control para pantallas anchas
  final String buttonLabel;

  const MarketDataWidget({
    super.key, 
    required this.setNum,
    required this.marketDataFuture,
    this.showCards = true, 
    this.showTitle = true, 
    this.showButton = true, // Por defecto se muestra
    this.buttonLabel = 'Ver Histórico',
  });

  void _showHistoryChartModal(BuildContext context, List<dynamic> fullHistory) {
    String selectedFilter = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          
          List<dynamic> displayHistory;
          int itemsToTake = fullHistory.length;

          switch (selectedFilter) {
            case '6M': itemsToTake = 6; break;
            case '1Y': itemsToTake = 12; break;
            case '5Y': itemsToTake = 60; break;
            case 'ALL': default: itemsToTake = fullHistory.length; break;
          }

          if (itemsToTake > fullHistory.length) {
            itemsToTake = fullHistory.length;
          }

          displayHistory = fullHistory.sublist(fullHistory.length - itemsToTake);

          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Histórico de Valor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              height: 380, 
              width: 400,
              child: Column(
                children: [
                  const Text('Evolución estimada del mercado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 15),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['6M', '1Y', '5Y', 'ALL'].map((filter) {
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(filter, style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                            )),
                            selected: isSelected,
                            selectedColor: Colors.orange,
                            backgroundColor: const Color(0xFF3A3A3A),
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => selectedFilter = filter);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // USAMOS EL DUMB WIDGET
                  Expanded(child: HistoryChartWidget(history: displayHistory)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: Colors.orange))),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>?>(
      future: marketDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0), 
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
            )
          );
        }

        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();

        final data = snapshot.data!;
        final history = data['history'] as List<dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: showTitle ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (showTitle)
                  Row(
                    children: [
                      if (data['isRetired'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data['isRetired'] ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: data['isRetired'] ? Colors.redAccent : Colors.green, width: 0.5),
                          ),
                          child: Text(
                            data['isRetired'] ? 'DESCATALOGADO' : 'EN TIENDAS',
                            style: TextStyle(
                              color: data['isRetired'] ? Colors.redAccent : Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ]
                  ),
                
                // CONDICIONAL PARA PANTALLAS ANCHAS
                if (showButton)
                  TextButton.icon(
                    icon: const Icon(Icons.show_chart, size: 18, color: Colors.orange),
                    label: Text(buttonLabel, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _showHistoryChartModal(context, history),
                  ),
              ],
            ),
            
            if (showCards)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _buildValueCard("Precio Retail", "${data['totalRetailPrice'] ?? data['estimatedRetailPrice']} €", Colors.blue, isDarkMode),
                    const SizedBox(width: 10),
                    _buildValueCard("Valor Mercado", "${data['currentMarketValue']} €", Colors.green, isDarkMode),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildValueCard(String label, String value, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}