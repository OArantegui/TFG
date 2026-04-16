import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WishlistSummaryCard extends StatelessWidget {
  final double totalValue;
  final double budget;
  final VoidCallback onBudgetUpdated; // Callback para recargar el padre

  // --- PARÁMETROS ESTILO MARKET_DATA_WIDGET ---
  final bool showButton;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;

  const WishlistSummaryCard({
    super.key,
    required this.totalValue,
    required this.budget,
    required this.onBudgetUpdated,
    this.showButton = false, // Por defecto oculto (útil para PC)
    this.buttonLabel = 'Estadísticas por temas',
    this.onButtonPressed,
  });

  void _editBudget(BuildContext context) {
    TextEditingController controller = TextEditingController(
      text: budget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajustar Presupuesto'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Presupuesto Máximo (€)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              double? newBudget = double.tryParse(controller.text);
              if (newBudget != null) {
                await ApiService().updateWishlistBudget(newBudget);
                Navigator.pop(ctx);
                onBudgetUpdated(); // Avisamos a la pantalla de que recargue
              }
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = budget > 0 ? totalValue / budget : 0.0;
    bool isOverBudget = progress > 1.0;
    Color statusColor = isOverBudget ? Colors.redAccent : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
      ),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Para que no ocupe toda la pantalla
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.favorite, color: Colors.pinkAccent),
              Text(
                '${totalValue.toStringAsFixed(2)} € / ${budget.toStringAsFixed(0)} €',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () => _editBudget(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: Colors.grey[800],
            color: statusColor,
            minHeight: 8,
          ),
          
          // --- NUEVO: BOTÓN INTEGRADO AL FINAL ---
          if (showButton && onButtonPressed != null) ...[
            const SizedBox(height: 15),
            const Divider(color: Colors.white10, height: 1), // Línea separadora
            const SizedBox(height: 5),
            TextButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.pie_chart, color: Colors.orange, size: 20),
              label: Text(
                buttonLabel,
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 45), // Fácil de pulsar
              ),
            ),
          ]
        ],
      ),
    );
  }
}