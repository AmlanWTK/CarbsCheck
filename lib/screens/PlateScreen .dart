import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/model/glucose_models.dart';
import 'package:carbcheck/services/food_serving_standards.dart';
import 'package:flutter/material.dart';

import 'package:carbcheck/services/serving_calculator.dart';
import 'package:carbcheck/services/nutrition_calculator.dart';
import 'package:carbcheck/services/glucose_impact_service.dart';

/// Main plate screen for meal composition and planning
///
/// Displays:
/// - Food list with portions
/// - Portion size selector
/// - Quantity controls
/// - Meal total nutrition
/// - Glucose impact preview
/// - Remove food functionality
class PlateScreen extends StatefulWidget {
  final List<PlateItem> initialItems;
  final Function(List<PlateItem>) onItemsChanged;
  final PatientGlucoseProfile? patientProfile;

  const PlateScreen({
    Key? key,
    this.initialItems = const [],
    required this.onItemsChanged,
    this.patientProfile,
  }) : super(key: key);

  @override
  State<PlateScreen> createState() => _PlateScreenState();
}

class _PlateScreenState extends State<PlateScreen> {
  late List<PlateItem> items;
  late LocalFoodDatabaseService _foodDatabase;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
    _foodDatabase = LocalFoodDatabaseService();
    _initializeDatabase();
  }

  /// Initialize local database
  Future<void> _initializeDatabase() async {
    try {
      await _foodDatabase.loadDatabase();
      print('✅ Database loaded for PlateScreen');
    } catch (e) {
      print('❌ Error loading database: $e');
    }
  }

  /// Update item's portion size
  void _updateItemUnit(int index, String newUnit) {
    setState(() {
      items[index] = items[index].copyWith(selectedUnit: newUnit);
    });
    widget.onItemsChanged(items);
  }

  /// Update item's quantity
  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        items[index] = items[index].copyWith(quantity: newQuantity);
      });
      widget.onItemsChanged(items);
    }
  }

  /// Remove item from plate
  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
    widget.onItemsChanged(items);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              items.insert(index, items[index]);
            });
            widget.onItemsChanged(items);
          },
        ),
      ),
    );
  }

  /// Get food from local database
  FoodItem? _getFoodFromDatabase(String foodName) {
    return _foodDatabase.getFoodByDescription(foodName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plate'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildFoodItem(index),
            ),
      bottomNavigationBar: items.isNotEmpty ? _buildBottomSummary() : null,
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No items added',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add foods to start building your meal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual food item card
  Widget _buildFoodItem(int index) {
    final item = items[index];
    final foodItem = _getFoodFromDatabase(item.foodName);

    if (foodItem == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.foodName),
                  Text(
                    '(Food not found)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ),
      );
    }

    final multiplier = ServingSizeCalculator.getPortionMultiplier(item.selectedUnit);
    final grams = (foodItem.servingSizeGrams * multiplier * item.quantity)
        .toStringAsFixed(0);
    final nutrition = foodItem.getNutrients(double.parse(grams));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.foodName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (nutrition.isNotEmpty)
                        Text(
                          '$grams g',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeItem(index),
                  tooltip: 'Remove item',
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Portion and quantity controls
            Row(
              children: [
                // Portion size selector
                Expanded(
                  child: _buildPortionSelector(index, item),
                ),
                const SizedBox(width: 12),

                // Quantity selector
                Expanded(
                  child: _buildQuantitySelector(index, item),
                ),
              ],
            ),

            // Nutrition info
            if (nutrition.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNutritionRow(nutrition),
            ],
          ],
        ),
      ),
    );
  }

  /// Portion size selector
  Widget _buildPortionSelector(int index, PlateItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portion',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          segments: ServingSizeCalculator.getValidPortions()
              .map((portion) => ButtonSegment<String>(
                label: Text(portion),
                value: portion,
              ))
              .toList(),
          selected: {item.selectedUnit},
          onSelectionChanged: (Set<String> newSelection) {
            _updateItemUnit(index, newSelection.first);
          },
        ),
      ],
    );
  }

  /// Quantity selector
  Widget _buildQuantitySelector(int index, PlateItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: item.quantity > 1
                  ? () => _updateItemQuantity(index, item.quantity - 1)
                  : null,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Expanded(
              child: TextFormField(
                initialValue: item.quantity.toString(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  if (int.tryParse(value) != null) {
                    _updateItemQuantity(index, int.parse(value));
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _updateItemQuantity(index, item.quantity + 1),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ],
    );
  }

  /// Nutrition info display
  Widget _buildNutritionRow(Map<String, dynamic> nutrition) {
    final carbs = nutrition['carbohydrates'] as double? ?? 0.0;
    final protein = nutrition['protein'] as double? ?? 0.0;
    final fat = nutrition['fat'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutrientItem(
            'Carbs',
            '${carbs.toStringAsFixed(1)}g',
            Colors.orange,
          ),
          _buildNutrientItem(
            'Protein',
            '${protein.toStringAsFixed(1)}g',
            Colors.green,
          ),
          _buildNutrientItem(
            'Fat',
            '${fat.toStringAsFixed(1)}g',
            Colors.red,
          ),
        ],
      ),
    );
  }

  /// Individual nutrient display
  Widget _buildNutrientItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Bottom summary bar
  Widget _buildBottomSummary() {
    // Calculate totals
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var item in items) {
      final foodItem = _getFoodFromDatabase(item.foodName);
      if (foodItem != null) {
        final multiplier = ServingSizeCalculator.getPortionMultiplier(item.selectedUnit);
        final grams = foodItem.servingSizeGrams * multiplier * item.quantity;
        final nutrition = foodItem.getNutrients(grams);

        totalCarbs += nutrition['carbohydrates'] as double? ?? 0.0;
        totalProtein += nutrition['protein'] as double? ?? 0.0;
        totalFat += nutrition['fat'] as double? ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${items.length} items in meal',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryNutrient('Carbs', '${totalCarbs.toStringAsFixed(1)}g', Colors.orange),
                _buildSummaryNutrient('Protein', '${totalProtein.toStringAsFixed(1)}g', Colors.green),
                _buildSummaryNutrient('Fat', '${totalFat.toStringAsFixed(1)}g', Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/nutrition_analysis',
                    arguments: items,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View Full Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Summary nutrient value
  Widget _buildSummaryNutrient(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
