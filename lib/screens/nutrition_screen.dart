import 'package:carbcheck/app_colors.dart';
import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/model/glucose_models.dart';
import 'package:carbcheck/model/nutrition_models.dart';
import 'package:flutter/material.dart';

import 'package:carbcheck/services/food_serving_standards.dart';
import 'package:carbcheck/services/serving_calculator.dart';
import 'package:carbcheck/services/nutrition_calculator.dart';
import 'package:carbcheck/services/glucose_impact_service.dart';

/// Enhanced nutrition analysis screen with detailed breakdown
/// 
/// Displays:
/// - Complete nutrition breakdown
/// - Macronutrient distribution (pie/bar charts)
/// - Glucose impact estimation
/// - Personalized recommendations
/// - Macro comparison to daily targets
class NutritionPlateScreen extends StatefulWidget {
  final List<PlateItem> items;
  final PatientGlucoseProfile? patientProfile;
  final Function(List<PlateItem>)? onModified;

  const NutritionPlateScreen({
    Key? key,
    required this.items,
    this.patientProfile,
    this.onModified,
  }) : super(key: key);

  @override
  State<NutritionPlateScreen> createState() => _NutritionPlateScreenState();
}

class _NutritionPlateScreenState extends State<NutritionPlateScreen> {
 late LocalFoodDatabaseService _foodDatabase;

  MealNutrientTotals? mealTotals;
  GlucoseImpactEstimate? glucoseImpact;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
   _foodDatabase = LocalFoodDatabaseService();
  _initializeAndCalculate();
  }

  /// Initialize database and calculate nutrition
Future<void> _initializeAndCalculate() async {
  try {
    await _foodDatabase.loadDatabase();
    await _calculateNutrition();
  } catch (e) {
    setState(() {
      errorMessage = 'Failed to load food database: $e';
      isLoading = false;
    });
  }
}

  /// Calculate complete meal nutrition
 Future<void> _calculateNutrition() async {
  try {
    setState(() => isLoading = true);

    // Build nutrition items from local database
    final nutritionItems = <FoodNutritionDetail>[];

    for (var item in widget.items) {
      try {
        // Get food from local database
        final foodItem = _foodDatabase.getFoodByDescription(item.foodName);
        if (foodItem == null) {
          print('⚠️ Food not found: ${item.foodName}');
          continue;
        }

        // Calculate portion size
        final multiplier = ServingSizeCalculator.getPortionMultiplier(item.selectedUnit);
        final grams = foodItem.servingSizeGrams * multiplier * item.quantity;

        // Get nutrients scaled to portion size
        final nutrition = foodItem.getNutrients(grams);

        final carbs = nutrition['carbohydrates'] as double? ?? 0.0;
        final protein = nutrition['protein'] as double? ?? 0.0;
        final fat = nutrition['fat'] as double? ?? 0.0;
        final calories = nutrition['calories'] as double? ?? 0.0;
        
        // Calculate net carbs (carbs - fiber)
        final fiber = nutrition['fiber'] as double? ?? 0.0;
        final netCarbs = carbs - fiber;

        nutritionItems.add(FoodNutritionDetail(
          foodName: item.foodName,
          grams: grams,
          carbs: carbs,
          fiber: fiber,
          netCarbs: netCarbs,
          protein: protein,
          fat: fat,
          calories: calories,
        ));

        print('✓ ${item.foodName}: carbs=$carbs, protein=$protein, fat=$fat');
      } catch (e) {
        print('⚠️ Error processing ${item.foodName}: $e');
        continue;
      }
    }

    // Calculate meal totals
    final totals = MealNutrientTotals.fromItems(nutritionItems);

    // Calculate glucose impact
    final baseline = widget.patientProfile?.currentGlucose ?? 105.0;
    final sensitivity = widget.patientProfile?.carbSensitivity ?? 12.0;

    final glucoseService = GlucoseImpactService();
    final impact = glucoseService.estimateMealImpact(
      items: nutritionItems,
      baselineGlucose: baseline,
      glucoseSensitivity: sensitivity,
    );

    setState(() {
      mealTotals = totals;
      glucoseImpact = impact;
      isLoading = false;
    });

    print('✅ Nutrition calculation complete!');
  } catch (e) {
    setState(() {
      errorMessage = 'Error calculating nutrition: $e';
      isLoading = false;
    });
    print('❌ Error in _calculateNutrition: $e');
  }
}





  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (mealTotals == null || glucoseImpact == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Analysis'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glucose impact card
            _buildGlucoseImpactCard(),
            const SizedBox(height: 20),

            // Nutrition summary
            _buildNutritionSummaryCard(),
            const SizedBox(height: 20),

            // Macro distribution
            _buildMacroDistributionCard(),
            const SizedBox(height: 20),

            // Detailed breakdown
            _buildDetailedBreakdownCard(),
            const SizedBox(height: 20),

            // Recommendations
            _buildRecommendationsCard(),
            const SizedBox(height: 20),

            // Item list
            _buildItemListCard(),
            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // LOADING STATE
  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Analysis')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ERROR STATE
  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Analysis')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Analysis')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.food_bank, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items to analyze',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  // GLUCOSE IMPACT CARD
  Widget _buildGlucoseImpactCard() {
    final color = _getColorForRisk(glucoseImpact!.riskLevel);

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glucose Impact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peak Glucose',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${glucoseImpact!.estimatedPeakGlucose.toStringAsFixed(0)} mg/dL',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rise',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${glucoseImpact!.glucoseRise.toStringAsFixed(0)} mg/dL',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    glucoseImpact!.riskLevel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              glucoseImpact!.riskDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // NUTRITION SUMMARY CARD
  Widget _buildNutritionSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Nutrition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionStat(
                  'Carbs',
                  '${mealTotals!.totalCarbs.toStringAsFixed(1)}g',
                  Colors.orange,
                ),
                _buildNutritionStat(
                  'Protein',
                  '${mealTotals!.totalProtein.toStringAsFixed(1)}g',
                  Colors.green,
                ),
                _buildNutritionStat(
                  'Fat',
                  '${mealTotals!.totalFat.toStringAsFixed(1)}g',
                  Colors.red,
                ),
                _buildNutritionStat(
                  'Calories',
                  '${mealTotals!.totalCalories.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MACRO DISTRIBUTION CARD
  Widget _buildMacroDistributionCard() {
    final distribution = NutritionCalculator.getMacroDistribution(
      carbs: mealTotals!.totalCarbs,
      protein: mealTotals!.totalProtein,
      fat: mealTotals!.totalFat,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macro Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDistributionBars(distribution),
          ],
        ),
      ),
    );
  }

  // DISTRIBUTION BARS
  Widget _buildDistributionBars(Map<String, double> distribution) {
    return Column(
      children: [
        _buildMacroBar(
          'Carbs',
          distribution['carbs'] ?? 0,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildMacroBar(
          'Protein',
          distribution['protein'] ?? 0,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildMacroBar(
          'Fat',
          distribution['fat'] ?? 0,
          Colors.red,
        ),
      ],
    );
  }

  // MACRO BAR
  Widget _buildMacroBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // DETAILED BREAKDOWN CARD
  Widget _buildDetailedBreakdownCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildBreakdownRow('Net Carbs', '${mealTotals!.totalNetCarbs.toStringAsFixed(1)}g'),
            _buildBreakdownRow('Fiber', '${mealTotals!.totalFiber.toStringAsFixed(1)}g'),
            const Divider(),
            _buildBreakdownRow('Total Items', '${mealTotals!.getItemCount()}'),
            _buildBreakdownRow('Average Per Item', '${(mealTotals!.totalCalories / mealTotals!.getItemCount()).toStringAsFixed(0)} cal'),
          ],
        ),
      ),
    );
  }

  // BREAKDOWN ROW
  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // RECOMMENDATIONS CARD
  Widget _buildRecommendationsCard() {
  if (glucoseImpact?.recommendations == null) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: AppColors.accentGradient,
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withOpacity(0.25),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.card.withOpacity(0.92), // frosted layer
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            glucoseImpact!.recommendations!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ITEM LIST CARD
  Widget _buildItemListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${widget.items.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) => _buildItemTile(index),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildItemTile(int index) {
  final item = widget.items[index];

  // Get food from local database
  final foodItem = _foodDatabase.getFoodByDescription(item.foodName);
  
  if (foodItem == null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.foodName, style: Theme.of(context).textTheme.bodySmall),
              Text(
                'Food not found',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const Icon(Icons.warning_amber, color: Colors.orange),
        ],
      ),
    );
  }

  // Calculate portion size
  final multiplier = ServingSizeCalculator.getPortionMultiplier(item.selectedUnit);
  final grams = foodItem.servingSizeGrams * multiplier * item.quantity;
  
  // Get nutrients scaled to portion size
  final nutrition = foodItem.getNutrients(grams);
  
  final carbs = nutrition['carbohydrates'] as double? ?? 0.0;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.foodName, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${grams.toStringAsFixed(0)}g (${item.selectedUnit} × ${item.quantity})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          '${carbs.toStringAsFixed(1)}g C',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    ),
  );
}


  // ACTION BUTTONS
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Plate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Save meal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meal saved')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Meal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      ],
    );
  }

  // HELPER: Nutrition stat
  Widget _buildNutritionStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // HELPER: Get color for risk
  Color _getColorForRisk(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
