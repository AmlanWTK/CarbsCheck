
//import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/widgets/food_search_autocomplete.dart';
import 'package:carbcheck/widgets/unit_to_gram.dart';
import 'package:flutter/material.dart';

import 'package:carbcheck/services/food_serving_standards.dart';
import 'package:carbcheck/services/usda_service.dart';

class MealEstimationScreen extends StatefulWidget {
  final Map<String, dynamic>? patientProfile;
  final Function(dynamic)? onMealEstimated;

  const MealEstimationScreen({
    Key? key,
    this.patientProfile,
    this.onMealEstimated,
  }) : super(key: key);

  @override
  State<MealEstimationScreen> createState() => _MealEstimationScreenState();
}

class _MealEstimationScreenState extends State<MealEstimationScreen> {
  // ✅ REPLACE WITH:
late LocalFoodDatabaseService _foodDatabase;
int currentStep = 1;
String? selectedMealType;
List<PlateItem> selectedFoods = [];
Map<String, dynamic>? estimatedNutrition;
Map<String, dynamic>? estimatedGlucose;
bool _calculationInProgress = false;

@override
void initState() {
  super.initState();
  // Initialize local food database
  _foodDatabase = LocalFoodDatabaseService();
  _initializeLocalDatabase();
}

/// Initialize local food database (one-time at startup)
Future<void> _initializeLocalDatabase() async {
  try {
    print('📥 Loading local food database...');
    await _foodDatabase.loadDatabase();
    print('✅ Food database ready!');
  } catch (e) {
    print('❌ Error loading database: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading food database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Estimation'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          const Divider(),
          Expanded(
            child: _buildStepContent(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepBadge(1, 'Type'),
          _buildStepBadge(2, 'Foods'),
          _buildStepBadge(3, 'Portions'),
          _buildStepBadge(4, 'Analysis'),
          _buildStepBadge(5, 'Save'),
        ],
      ),
    );
  }

  Widget _buildStepBadge(int step, String label) {
    final isActive = currentStep == step;
    final isCompleted = currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? Colors.teal : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive || isCompleted ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive || isCompleted ? Colors.teal : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return _buildMealTypeStep();
      case 2:
        return _buildFoodSelectionStep();
      case 3:
        return _buildPortionAdjustmentStep();
      case 4:
        return _buildAnalysisStep();
      case 5:
        return _buildConfirmationStep();
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  Widget _buildMealTypeStep() {
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select meal type',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...mealTypes.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceChip(
              label: Text(type.toUpperCase()),
              selected: selectedMealType == type,
              onSelected: (selected) {
                setState(() => selectedMealType = selected ? type : null);
              },
            ),
          );
        }),
      ],
    );
  }

 // ❌ DELETE your old _buildFoodSelectionStep() completely

// ✅ REPLACE WITH:
Widget _buildFoodSelectionStep() {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Search and add foods',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 16),
      
      // 🔍 Use the new autocomplete widget
      FoodSearchAutocomplete(
        onFoodSelected: (foodName) {
          // Get the food from local database to get actual serving size
          final foodItem = _foodDatabase.getFoodByDescription(foodName);
          
          if (foodItem != null) {
            setState(() {
              selectedFoods.add(PlateItem(
                foodName: foodItem.description,
                selectedUnit: foodItem.servingSizeUnit,
                quantity: 1,
                portionInGrams: foodItem.servingSizeGrams,
                standardServingGrams: foodItem.servingSizeGrams,
                servingSizeDesc: 'Standard serving',
              ));
            });
            
            print('✅ Added: ${foodItem.description}');
          } else {
            print('⚠️ Food not found in database');
          }
        },
        excludeFoods: selectedFoods.map((f) => f.foodName).toList(),
      ),
      
      const SizedBox(height: 16),
      
      // Show selected foods
      if (selectedFoods.isNotEmpty) ...[
        Text(
          'Selected foods (${selectedFoods.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...selectedFoods.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Dismissible(
            key: Key('${item.foodName}_$index'),
            onDismissed: (_) {
              setState(() => selectedFoods.removeAt(index));
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(item.foodName),
                  subtitle: Text('${item.servingSizeDesc} (${item.portionInGrams.toStringAsFixed(0)}g)'),
                  trailing: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          );
        }),
      ],
    ],
  );
}

  Widget _buildPortionAdjustmentStep() {
    if (selectedFoods.isEmpty) {
      return const Center(
        child: Text('No foods selected. Go back to add foods.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Adjust portion sizes',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...selectedFoods.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildFoodPortionCard(index, item);
        }),
      ],
    );
  }

 /// Generate unit map for a food
Map<String, double> getUnits(FoodItem food) {
  return {
    'Serving': food.servingSizeGrams,
    '100 g': 100.0, // optional: let user switch to grams
  };
}
Widget _buildFoodPortionCard(int index, PlateItem item) {
  // 🔹 Generate units dynamically
  final Map<String, double> units = {
    'Serving': item.standardServingGrams,
    '100 g': 100.0,
  };

  // 🔹 Debug print to see what is null
  print('🔹 Building card for: ${item.foodName}');
  print('  selectedUnit: ${item.selectedUnit}');
  print('  quantity: ${item.quantity}');
  print('  portionInGrams: ${item.portionInGrams}');
  print('  standardServingGrams: ${item.standardServingGrams}');
  print('  units map: $units');

  // 🔹 Safe access to selected unit
  final selectedUnitGrams = units[item.selectedUnit] ?? item.standardServingGrams;
  final totalGrams = selectedUnitGrams * item.quantity;

  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name
          Text(
            item.foodName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Quantity selector
          Row(
            children: [
              const Text('Quantity'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: item.quantity > 1
                    ? () {
                        setState(() {
                          selectedFoods[index] =
                              item.copyWith(quantity: item.quantity - 1);
                        });
                      }
                    : null,
              ),
              Text('${item.quantity}'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    selectedFoods[index] =
                        item.copyWith(quantity: item.quantity + 1);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Unit selector
          const Text('Unit'),
          Wrap(
            spacing: 8,
            children: units.keys.map((unit) {
              return ChoiceChip(
                label: Text(unit),
                selected: item.selectedUnit == unit,
                onSelected: (_) {
                  setState(() {
                    selectedFoods[index] =
                        item.copyWith(selectedUnit: unit);
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Portion summary (safe, uses totalGrams)
          Text(
            'Portion: ${totalGrams.toStringAsFixed(0)} g',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}



  // ✅ STEP 4: ANALYSIS - FIXED
   Widget _buildAnalysisStep() {
    if (estimatedNutrition == null || estimatedGlucose == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing meal...'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGlucoseCard(),
        const SizedBox(height: 16),
        _buildNutritionCard(),
        const SizedBox(height: 16),
        _buildMacroCard(),
        const SizedBox(height: 16),
        _buildRecommendationsCard(),
      ],
    );
  }


  // ✅ FIXED: Now fetches nutrition from USDA API
Future<void> _calculateEstimates() async {
  if (_calculationInProgress) return;

  setState(() => _calculationInProgress = true);

  try {
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCalories = 0;

    for (var food in selectedFoods) {
      try {
        // ✅ Fetch the food from local database
        final foodItem = _foodDatabase.getFoodByDescription(food.foodName);

        if (foodItem == null) {
          print('⚠️ Food not found in database: ${food.foodName}');
          continue;
        }

        // ⚡ Calculate actual portion in grams based on user quantity
        final portionGrams = food.standardServingGrams * food.quantity;

        // ⚡ Get scaled nutrients
        final nutrients = foodItem.getNutrients(portionGrams);

        final carbs = nutrients['carbs'] ?? 0.0;
        final protein = nutrients['protein'] ?? 0.0;
        final fat = nutrients['fat'] ?? 0.0;
        final calories = nutrients['calories'] ?? (carbs*4 + protein*4 + fat*9);

        print('✓ ${food.foodName}: quantity=${food.quantity}, portion=${portionGrams}g, carbs=$carbs, protein=$protein, fat=$fat, cal=$calories');

        // ⚡ Add to totals
        totalCarbs += carbs;
        totalProtein += protein;
        totalFat += fat;
        totalCalories += calories;

      } catch (e) {
        print('⚠️ Error processing ${food.foodName}: $e');
      }
    }

    // ✅ Calculate estimated glucose
    final peakGlucose = 100 + totalCarbs * 0.5;
    final glucoseRise = peakGlucose - 100;

    final riskLevel = peakGlucose < 140
        ? 'low'
        : peakGlucose < 180
            ? 'medium'
            : 'high';

    final nutritionEstimate = {
      'totalCarbs': totalCarbs,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCalories': totalCalories,
    };

    final glucoseEstimate = {
      'estimatedPeakGlucose': peakGlucose,
      'glucoseRise': glucoseRise,
      'riskLevel': riskLevel,
      'riskDescription': _riskDescription(riskLevel),
      'recommendations': _getRecommendations(peakGlucose),
    };

    if (!mounted) return;

    setState(() {
      estimatedNutrition = nutritionEstimate;
      estimatedGlucose = glucoseEstimate;
      _calculationInProgress = false;
    });

    print('✅ Analysis complete! Carbs: $totalCarbs, Protein: $totalProtein, Fat: $totalFat, Peak glucose: $peakGlucose');

  } catch (e) {
    if (!mounted) return;
    setState(() => _calculationInProgress = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analysis failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
    print('❌ Error in _calculateEstimates: $e');
  }
}





  String _riskDescription(String risk) {
    switch (risk) {
      case 'low':
        return 'Minimal glucose impact.';
      case 'medium':
        return 'Moderate glucose rise.';
      default:
        return 'High glucose spike expected.';
    }
  }

  String _getRecommendations(double peakGlucose) {
    if (peakGlucose < 140) {
      return 'Great choice!';
    } else if (peakGlucose < 180) {
      return 'Add protein or fiber to reduce spike.';
    } else {
      return 'Reduce portion size or walk after meal.';
    }
  }



  Widget _buildGlucoseCard() {
    if (estimatedGlucose == null) {
      return const Card(child: Center(child: Text('No data')));
    }

    final color = _getColorForRisk(estimatedGlucose!['riskLevel'] ?? 'low');

    return Card(
      color: Colors.white,
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
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
                    Text('Peak', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${(estimatedGlucose!['estimatedPeakGlucose'] as num).toStringAsFixed(0)} mg/dL',
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
                    Text('Rise', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      '+${(estimatedGlucose!['glucoseRise'] as num).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    (estimatedGlucose!['riskLevel'] as String).toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              estimatedGlucose!['riskDescription'] as String? ?? 'No description',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    if (estimatedNutrition == null) {
      return const Card(child: Center(child: Text('No data')));
    }

    final carbs = (estimatedNutrition!['totalCarbs'] as num).toDouble();
    final protein = (estimatedNutrition!['totalProtein'] as num).toDouble();
    final fat = (estimatedNutrition!['totalFat'] as num).toDouble();
    final calories = (estimatedNutrition!['totalCalories'] as num).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Nutrition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionStat('Carbs', '${carbs.toStringAsFixed(1)}g', Colors.orange),
                _buildNutritionStat('Protein', '${protein.toStringAsFixed(1)}g', Colors.green),
                _buildNutritionStat('Fat', '${fat.toStringAsFixed(1)}g', Colors.red),
                _buildNutritionStat('Calories', '${calories.toStringAsFixed(0)}', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }

  Widget _buildMacroCard() {
    if (estimatedNutrition == null) {
      return const Card(child: Center(child: Text('No data')));
    }

    final carbs = (estimatedNutrition!['totalCarbs'] as num).toDouble();
    final protein = (estimatedNutrition!['totalProtein'] as num).toDouble();
    final fat = (estimatedNutrition!['totalFat'] as num).toDouble();

    final total = carbs * 4 + protein * 4 + fat * 9;
    final carbsPct = total > 0 ? (carbs * 4) / total * 100 : 0.0;
    final proteinPct = total > 0 ? (protein * 4) / total * 100 : 0.0;
    final fatPct = total > 0 ? (fat * 9) / total * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macro Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMacroBar('Carbs', carbsPct, Colors.orange),
            const SizedBox(height: 12),
            _buildMacroBar('Protein', proteinPct, Colors.green),
            const SizedBox(height: 12),
            _buildMacroBar('Fat', fatPct, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text('${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    estimatedGlucose?['recommendations'] as String? ?? 'No specific recommendations',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildConfirmationStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: Icon(Icons.check_circle, size: 64, color: Colors.green[400])),
        const SizedBox(height: 16),
        Text(
          'Ready to Save',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your meal estimation is complete',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal Summary',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Meal Type', selectedMealType?.toUpperCase() ?? 'Unknown'),
                _buildSummaryRow('Items', '${selectedFoods.length} foods'),
                _buildSummaryRow('Total Carbs', '${estimatedNutrition?['totalCarbs'].toStringAsFixed(1) ?? '0'}g'),
                _buildSummaryRow('Glucose Peak', '${estimatedGlucose?['estimatedPeakGlucose'].toStringAsFixed(0) ?? '0'} mg/dL'),
                _buildSummaryRow('Risk Level', estimatedGlucose?['riskLevel'].toUpperCase() ?? 'Unknown'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (currentStep > 1)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentStep--;
                    estimatedNutrition = null;
                    estimatedGlucose = null;
                  });
                },
                child: const Text('Back'),
              ),
            ),
          if (currentStep > 1) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedToNextStep()
                  ? () {
                      setState(() => currentStep++);
                      if (currentStep == 4) {
                        _calculateEstimates(); // ✅ SAFE TRIGGER
                      }
                    }
                  : null,
              child: Text(currentStep == 5 ? 'Save' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (currentStep) {
      case 1:
        return selectedMealType != null;
      case 2:
      case 3:
        return selectedFoods.isNotEmpty;
      case 4:
        return estimatedNutrition != null && estimatedGlucose != null;
      default:
        return true;
    }
  }

}
