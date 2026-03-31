import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WishlistSummaryCard extends StatelessWidget {
  final double totalValue;
  final double budget;
  final VoidCallback onBudgetUpdated; // TFG: Callback para recargar el padre

  const WishlistSummaryCard({
    super.key,
    required this.totalValue,
    required this.budget,
    required this.onBudgetUpdated,
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
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF2A2A2A),
      width: double.infinity,
      child: Column(
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
        ],
      ),
    );
  }
}