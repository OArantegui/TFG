/*import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WishlistThemeChartWidget extends StatefulWidget {
  final Map<String, double> themeData;

  const WishlistThemeChartWidget({super.key, required this.themeData});

  @override
  State<WishlistThemeChartWidget> createState() => _WishlistThemeChartWidgetState();
}

class _WishlistThemeChartWidgetState extends State<WishlistThemeChartWidget> {
  int touchedIndex = -1;

  // Paleta de colores Material para los temas (anti-diseño complejo, funcional)
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

    final totalBudget = widget.themeData.values.fold(0.0, (sum, val) => sum + val);

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
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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
            // Leyenda opcional para saber qué es cada color
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _generateLegend(),
            )
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
      final fontSize = isTouched ? 16.0 : 0.0; // Solo mostramos texto al tocar para que sea limpio
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (amount / total * 100).toStringAsFixed(1);
      final color = _colors[i % _colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: isTouched ? '$percentage%\n$amount€' : '',
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
            Container(width: 12, height: 12, color: _colors[i % _colors.length]),
            const SizedBox(width: 4),
            Text(themeName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
      i++;
    });
    return legend;
  }
}*/
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WishlistThemeChartWidget extends StatefulWidget {
  final Map<String, double> themeData;

  const WishlistThemeChartWidget({super.key, required this.themeData});

  @override
  State<WishlistThemeChartWidget> createState() => _WishlistThemeChartWidgetState();
}

class _WishlistThemeChartWidgetState extends State<WishlistThemeChartWidget> {
  int touchedIndex = -1;

  // Paleta de colores Material para los temas (anti-diseño complejo, funcional)
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

    final totalBudget = widget.themeData.values.fold(0.0, (sum, val) => sum + val);

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
                        // SOLO evaluamos cuando el usuario hace el gesto completo de "tocar y soltar" (Tap Up)
                        if (event is FlTapUpEvent) {
                          // Si no hemos tocado la gráfica en absoluto, no hacemos nada
                          if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            return;
                          }

                          final currentTouch = pieTouchResponse.touchedSection!.touchedSectionIndex;

                          // El índice -1 significa que tocó el hueco central o fuera del pastel. 
                          // Si toca fuera, hacemos 'return' para que no cambie el estado actual (no se cierra).
                          if (currentTouch == -1) {
                            return;
                          }

                          // Lógica de INTERRUPTOR PURO:
                          // Si tocas el que ya está seleccionado, lo cierra (-1).
                          // Si tocas otro diferente, lo abre (currentTouch).
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
            )
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
      final formattedAmount = amount.toStringAsFixed(2); // Mantenemos los 2 decimales
      
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
            Container(width: 12, height: 12, color: _colors[i % _colors.length]),
            const SizedBox(width: 4),
            Text(themeName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
      i++;
    });
    return legend;
  }
}