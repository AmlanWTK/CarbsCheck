import 'package:flutter/material.dart';

class NutritionBreakdownCard extends StatelessWidget {
  final double carbs;
  final double protein;
  final double fat;
  final double calories;
  final bool showCalories;

  const NutritionBreakdownCard({
    Key? key,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
    this.showCalories = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientColumn('Carbs', carbs, 'g', Colors.orange),
                _buildNutrientColumn('Protein', protein, 'g', Colors.green),
                _buildNutrientColumn('Fat', fat, 'g', Colors.red),
                if (showCalories)
                  _buildNutrientColumn('Calories', calories, 'kcal', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
