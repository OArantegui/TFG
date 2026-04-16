import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryChartWidget extends StatelessWidget {
  final List<dynamic> history;

  const HistoryChartWidget({super.key, required this.history});

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

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('Sin datos históricos', style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = 0;

    for (int i = 0; i < history.length; i++) {
      double price = (history[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minY) minY = price;
      if (price > maxY) maxY = price;
    }

    // Salvavidas de seguridad matemática
    if (minY == double.infinity) minY = 0;

    if (minY == maxY) {
      minY = minY * 0.95;
      maxY = maxY * 1.05;
    }

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
}