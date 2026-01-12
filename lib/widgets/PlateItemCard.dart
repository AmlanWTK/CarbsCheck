import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/widgets/unit_to_gram.dart';
import 'package:flutter/material.dart';
class PlateItemCard extends StatelessWidget {
  final PlateItem item;
  final ValueChanged<PlateItem> onChanged;
  final VoidCallback onRemove;

  const PlateItemCard({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final units = unitToGram[item.foodName]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food name
            const Text('Food'),
            DropdownButton<String>(
              value: item.foodName,
              isExpanded: true,
              items: unitToGram.keys
                  .map(
                    (food) => DropdownMenuItem(
                      value: food,
                      child: Text(food.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final firstUnit = unitToGram[value!]!.keys.first;
                onChanged(item.copyWith(
                  foodName: value,
                  selectedUnit: firstUnit,
                  quantity: 1,
                ));
              },
            ),
            const SizedBox(height: 12),

            // Quantity input
            const Text('Quantity'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter quantity',
              ),
              onChanged: (value) {
                final q = int.tryParse(value) ?? 1;
                onChanged(item.copyWith(quantity: q));
              },
            ),
            const SizedBox(height: 12),

            // Unit selection (Small / Medium / Large)
            const Text('Select Unit'),
            Wrap(
              spacing: 8,
              children: units.keys.map((unit) {
                return ChoiceChip(
                  label: Text(unit),
                  selected: item.selectedUnit == unit,
                  onSelected: (_) => onChanged(item.copyWith(selectedUnit: unit)),
                );
              }).toList(),
            ),

            // Remove button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
