import 'package:flutter/material.dart';

class NutritionPlateScreen extends StatelessWidget {
  final List<Map<String, dynamic>> plateItems;
  const NutritionPlateScreen({super.key, required this.plateItems});

  @override
  Widget build(BuildContext context) {
    // Example nutrition calculation (replace with USDA API later)
    double totalCarbs = 0, totalFiber = 0, totalCalories = 0;

    List<Map<String, dynamic>> itemNutrition = [];

    for (var item in plateItems) {
      // Example: assume 100g = carbs 28g, fiber 1g, calories 130 kcal
      double quantity = item['quantity'];
      double carbs = 28.0 * (quantity / 100);
      double fiber = 1.0 * (quantity / 100);
      double calories = 130.0 * (quantity / 100);

      totalCarbs += carbs;
      totalFiber += fiber;
      totalCalories += calories;

      itemNutrition.add({
        "food": item['food'],
        "quantity": quantity,
        "carbs": carbs,
        "fiber": fiber,
        "netCarbs": carbs - fiber,
        "calories": calories
      });
    }

    double totalNetCarbs = totalCarbs - totalFiber;

    // Determine estimated glucose impact (simple demo)
    String glucoseImpact = totalNetCarbs > 50
        ? "High"
        : totalNetCarbs > 25
            ? "Medium"
            : "Low";

    return Scaffold(
      appBar: AppBar(title: const Text("Plate Nutrition")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Item-wise Nutrition:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: itemNutrition.length,
                itemBuilder: (context, index) {
                  final item = itemNutrition[index];
                  return ListTile(
                    title: Text("${item['food']} - ${item['quantity']}g"),
                    subtitle: Text(
                        "Carbs: ${item['carbs'].toStringAsFixed(1)} g, Net: ${item['netCarbs'].toStringAsFixed(1)} g, Calories: ${item['calories'].toStringAsFixed(0)} kcal"),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Total Net Carbs: ${totalNetCarbs.toStringAsFixed(1)} g",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Estimated Glucose Impact: $glucoseImpact",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
