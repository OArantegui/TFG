import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MarketDataWidget extends StatelessWidget {
  final String setNum;
  final Future<Map<String, dynamic>?> marketDataFuture;
  
  // Banderas para reutilizar el widget de forma inteligente
  final bool showCards; 
  final bool showTitle;
  final String buttonLabel;

  const MarketDataWidget({
    super.key, 
    required this.setNum,
    required this.marketDataFuture,
    this.showCards = true, // Por defecto se ven (pantalla de detalles)
    this.showTitle = true, // Por defecto se ve (pantalla de detalles)
    this.buttonLabel = 'Ver Histórico',
  });

  String _getMonthName(String monthNumber) {
    switch (monthNumber) {
      case '01': return 'Enero';
      case '02': return 'Febrero';
      case '03': return 'Marzo';
      case '04': return 'Abril';
      case '05': return 'Mayo';
      case '06': return 'Junio';
      case '07': return 'Julio';
      case '08': return 'Agosto';
      case '09': return 'Septiembre';
      case '10': return 'Octubre';
      case '11': return 'Noviembre';
      case '12': return 'Diciembre';
      default: return monthNumber;
    }
  }
  Widget _buildChart(List<dynamic> history) {
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = 0;

    for (int i = 0; i < history.length; i++) {
      double price = (history[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minY) minY = price;
      if (price > maxY) maxY = price;
    }

    // Salvavidas por si la línea es completamente plana
    if (minY == maxY) {
      minY = minY * 0.95;
      maxY = maxY * 1.05;
    }

    // Salvavidas por si solo hay un punto de datos (set que acaba de salir)
    double maxX = (history.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0; 

    double xInterval = (history.length / 5).ceilToDouble();
    if (xInterval == 0) xInterval = 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY * 0.95,
        maxY: maxY * 1.05,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, 
            color: Colors.greenAccent, 
            barWidth: 3,
            dotData: FlDotData(show: history.length <= 24),
            belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withOpacity(0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (value == value.toInt() && value >= 0 && value < history.length) {
                  int index = value.toInt();
                  String dateStr = history[index]['month'].toString(); 
                  String yearStr = dateStr.split('-')[0].substring(2);
                  String monthStr = dateStr.split('-')[1];
                  String monthName = _getMonthName(monthStr).substring(0, 3);
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('$monthName $yearStr', 
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}€', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  void _showHistoryChartModal(BuildContext context, List<dynamic> fullHistory) {
    // Estado inicial al abrir el popup
    String selectedFilter = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          
          // Lógica Matemática del Filtro
          List<dynamic> displayHistory;
          int itemsToTake = fullHistory.length;

          switch (selectedFilter) {
            case '6M': itemsToTake = 6; break;
            case '1Y': itemsToTake = 12; break;
            case '5Y': itemsToTake = 60; break;
            case 'ALL': default: itemsToTake = fullHistory.length; break;
          }

          // Si el set es más joven que el tiempo seleccionado, cogemos todo lo que hay
          if (itemsToTake > fullHistory.length) {
            itemsToTake = fullHistory.length;
          }

          // Recortamos el array quedándonos solo con los últimos X elementos
          displayHistory = fullHistory.sublist(fullHistory.length - itemsToTake);

          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Histórico de Valor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              height: 380, // Un poco más alto para hacer hueco a los botones
              width: 400,
              child: Column(
                children: [
                  const Text('Evolución estimada del mercado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 15),

                  // BOTONES DE FILTRO (Usamos ChoiceChip nativos de Material)
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
                                // Aquí ocurre la magia: recargamos solo el modal
                                setState(() => selectedFilter = filter);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pasamos el array recortado en lugar de fullHistory
                  Expanded(child: _buildChart(displayHistory)),
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
          // Indicador de carga súper minimalista para no desentonar
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
            // FILA DEL TÍTULO Y BOTÓN
            Row(
              // Si no hay título, centramos el botón. Si hay título, lo mandamos a los extremos.
              mainAxisAlignment: showTitle ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (showTitle)
                  Row(
                    children: [
                      //ETIQUETA DE ESTADO (Descatalogado / En tiendas)
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
                
                TextButton.icon(
                  icon: const Icon(Icons.show_chart, size: 18, color: Colors.orange),
                  label: Text(buttonLabel, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () => _showHistoryChartModal(context, history),
                ),
              ],
            ),
            
            // TARJETAS DE COMPARACIÓN (Se ocultan si showCards es falso)
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