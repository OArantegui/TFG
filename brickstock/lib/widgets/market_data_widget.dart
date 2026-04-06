import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class MarketDataWidget extends StatelessWidget {
  final String setNum;

  const MarketDataWidget({super.key, required this.setNum});

  Widget _buildChart(List<dynamic> history) {
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = 0;

    // Convertimos el JSON en coordenadas (X = índice del mes, Y = precio)
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
        minY: minY * 0.95, // Damos margen abajo
        maxY: maxY * 1.05, // Damos margen arriba
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true), // Muestra los puntitos
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2), // Sombra debajo de la línea
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
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < history.length) {
                  // Extraemos solo el mes (ej: de "2026-03" sacamos "03")
                  String monthStr = history[index]['month'].toString().split('-')[1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Mes $monthStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        Text(
          'Análisis de Mercado',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, dynamic>?>(
          future: ApiService().getSetMarketData(setNum),
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
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              const Text("Precio Retail", style: TextStyle(fontSize: 12)),
                              Text("$estimatedRetailPrice €", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              const Text("Valor Mercado", style: TextStyle(fontSize: 12)),
                              Text("$currentMarketValue €", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Evolución (Últimos 6 meses)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: _buildChart(history),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}