import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MarketDataWidget extends StatelessWidget {
  final String setNum;
  final Future<Map<String, dynamic>?> marketDataFuture;

  const MarketDataWidget({
    super.key, 
    required this.setNum,
    required this.marketDataFuture,
  });

  // Función para convertir el número de mes en letras (Abreviado)
  String _getMonthName(String monthNumber) {
    switch (monthNumber) {
      case '01': return 'Ene';
      case '02': return 'Feb';
      case '03': return 'Mar';
      case '04': return 'Abr';
      case '05': return 'May';
      case '06': return 'Jun';
      case '07': return 'Jul';
      case '08': return 'Ago';
      case '09': return 'Sep';
      case '10': return 'Oct';
      case '11': return 'Nov';
      case '12': return 'Dic';
      default: return '';
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

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: minY * 0.95,
        maxY: maxY * 1.05,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.greenAccent, 
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.greenAccent.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, 
              getTitlesWidget: (value, meta) {
                if (value == value.toInt() && value >= 0 && value < history.length) {
                  int index = value.toInt();
                  String monthStr = history[index]['month'].toString().split('-')[1];
                  
                  // TFG: Aquí usamos nuestra nueva función
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_getMonthName(monthStr), style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}€', style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  void _showHistoryChartModal(BuildContext context, List<dynamic> history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Evolución de Mercado'),
        content: SizedBox(
          height: 300, 
          width: 400,
          child: Column(
            children: [
              const Text(
                'Datos de mercado de los últimos 6 meses',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildChart(history)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
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
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Text("No hay datos de mercado disponibles para este set.");
        }

        final marketData = snapshot.data!;
        final currentMarketValue = marketData['currentMarketValue'].toString();
        final estimatedRetailPrice = marketData['estimatedRetailPrice'].toString();
        final history = marketData['history'] as List<dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comparativa de Precios',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.show_chart),
                  label: const Text('Ver Histórico'),
                  onPressed: () => _showHistoryChartModal(context, history),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text("Precio Retail", style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.blue[200] : Colors.black87)),
                          Text(
                            "$estimatedRetailPrice €", 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: isDarkMode ? Colors.blue[300] : Colors.blue[800]
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: isDarkMode ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text("Valor Mercado", style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.green[200] : Colors.black87)),
                          Text(
                            "$currentMarketValue €", 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: isDarkMode ? Colors.green[300] : Colors.green[800]
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}