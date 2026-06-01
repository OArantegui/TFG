import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WishlistThemeChartWidget extends StatefulWidget {
  final Map<String, double> themeData;

  const WishlistThemeChartWidget({super.key, required this.themeData});

  @override
  State<WishlistThemeChartWidget> createState() =>
      _WishlistThemeChartWidgetState();
}

class _WishlistThemeChartWidgetState extends State<WishlistThemeChartWidget> {
  int touchedIndex = -1;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.themeData.isEmpty) {
      return const SizedBox(); // No hay datos
    }

    final totalBudget = widget.themeData.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (event is FlTapUpEvent) {
                          //Solo reacciona si toca y suelta
                          if (pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }

                          final currentTouch = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;

                          if (currentTouch == -1) {
                            return;
                          }

                          if (touchedIndex == currentTouch) {
                            touchedIndex = -1;
                          } else {
                            touchedIndex = currentTouch;
                          }
                        }
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _generateSections(totalBudget),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _generateLegend(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(double total) {
    List<PieChartSectionData> sections = [];
    int i = 0;

    widget.themeData.forEach((themeName, amount) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 60.0 : 50.0;

      final percentage = (amount / total * 100).toStringAsFixed(1);
      final formattedAmount = amount.toStringAsFixed(
        2,
      ); // Mantenemos los 2 decimales

      final color = _colors[i % _colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: isTouched ? '$percentage%\n$formattedAmount€' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  List<Widget> _generateLegend() {
    List<Widget> legend = [];
    int i = 0;
    widget.themeData.forEach((themeName, amount) {
      legend.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: _colors[i % _colors.length],
            ),
            const SizedBox(width: 4),
            Text(
              themeName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
      i++;
    });
    return legend;
  }
}
