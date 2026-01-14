
//import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/app_colors.dart';
import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/widgets/food_search_autocomplete.dart';
import 'package:carbcheck/widgets/unit_to_gram.dart';
import 'package:flutter/material.dart';

import 'package:carbcheck/services/food_serving_standards.dart';
import 'package:carbcheck/services/usda_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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
        title:  Center(
          child: Text('Meal Estimation',
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.w500,
            fontSize: 25,
            color: AppColors.borderDark
          ),
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.bg(context),
  foregroundColor: AppColors.text(context),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
           Divider(color: AppColors.btnPrimary),
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
    color: AppColors.card, // Instead of Colors.grey[100]
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
          color: isActive || isCompleted
              ? AppColors.primary // Active/Completed
              : AppColors.border, // Inactive
        ),
        child: Center(
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive || isCompleted
                  ? AppColors.textOnPrimary // white text on primary
                  : AppColors.textSecondary, // gray text
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
          color: isActive || isCompleted
              ? AppColors.primary
              : AppColors.textSecondary,
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
  final List<Map<String, String>> mealCards = [
    {"title": "Breakfast", "animation": "assets/Breakfast.json"},
    {"title": "Lunch", "animation": "assets/launch.json"},
    {"title": "Dinner", "animation": "assets/dinner.json"},
    {"title": "Snack", "animation": "assets/snacks.json"},
  ];

  // Track which card is currently being pressed for scale animation
  Map<String, bool> _isPressed = {
    "Breakfast": false,
    "Lunch": false,
    "Dinner": false,
    "Snack": false,
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const
       Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Select meal type',
          style: TextStyle(fontSize: 17, color: Color(0xFF546E7A)), // AppColors.textSecondary
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            itemCount: mealCards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final meal = mealCards[index];
              final isSelected = selectedMealType == meal["title"];
              final isPressed = _isPressed[meal["title"]] ?? false;

              return GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isPressed[meal["title"]!] = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isPressed[meal["title"]!] = false;
                    selectedMealType = meal["title"]; // main state updated here
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isPressed[meal["title"]!] = false;
                  });
                },
                child: AnimatedScale(
                  scale: isPressed ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal[50] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lottie animation
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Lottie.asset(
                              meal["animation"]!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Meal title
                        // Text(
                        //   meal["title"]!,
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //     color: isSelected ? Colors.teal : Colors.black87,
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        // Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.teal : Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(36),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedMealType = meal["title"]; // parent state updated
                              });
                            },
                            child: Text(
                              'Select ${meal["title"]}',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
  Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      'Selected foods (${selectedFoods.length})',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  ),

  const SizedBox(height: 12),

  ...selectedFoods.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;

    return Dismissible(
      key: Key('${item.foodName}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.error,
        ),
      ),
      onDismissed: (_) {
        setState(() => selectedFoods.removeAt(index));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: AppColors.primaryGradientLight,
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
  color: AppColors.primary.withOpacity(0.25),
  width: 1,
),

          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
  color: AppColors.primary,
  width: 1,
),

                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              item.foodName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${item.servingSizeDesc} • ${item.portionInGrams.toStringAsFixed(0)} g',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              onPressed: () {
                setState(() => selectedFoods.removeAt(index));
              },
            ),
          ),
        ),
      ),
    );
  }),
]
    ]
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

  final selectedUnitGrams =
      units[item.selectedUnit] ?? item.standardServingGrams;
  final totalGrams = selectedUnitGrams * item.quantity;

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.primaryGradientLight,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🍽 Food name header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.foodName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔢 Quantity selector
            Row(
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                _QuantityButton(
                  icon: Icons.remove,
                  enabled: item.quantity > 1,
                  onTap: () {
                    setState(() {
                      selectedFoods[index] =
                          item.copyWith(quantity: item.quantity - 1);
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  enabled: true,
                  onTap: () {
                    setState(() {
                      selectedFoods[index] =
                          item.copyWith(quantity: item.quantity + 1);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ⚖ Unit selector
            Text(
              'Unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: units.keys.map((unit) {
                final isSelected = item.selectedUnit == unit;
                return ChoiceChip(
                  label: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary.withOpacity(0.08),
                    ),
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedFoods[index] =
                          item.copyWith(selectedUnit: unit);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 📊 Portion summary
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Portion: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${totalGrams.toStringAsFixed(0)} g',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

Color glucoseRiskColor(String level) {
  switch (level.toLowerCase()) {
    case 'high':
      return const Color(0xFFD32F2F); // medical red
    case 'medium':
      return const Color(0xFFF9A825); // amber
    default:
      return const Color(0xFF2E7D32); // safe green
  }
}

BoxDecoration metricCardDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    gradient: AppColors.primaryGradientLight,
    border: Border.all(
      color: AppColors.textPrimary.withOpacity(0.08),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

  Widget _buildGlucoseCard() {
  if (estimatedGlucose == null) {
    return const SizedBox.shrink();
  }

  final riskLevel = estimatedGlucose!['riskLevel'] ?? 'low';
  final color = glucoseRiskColor(riskLevel);

  return Container(
    decoration: metricCardDecoration(),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glucose Impact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _metricColumn(
              'Peak',
              '${(estimatedGlucose!['estimatedPeakGlucose'] as num).toStringAsFixed(0)} mg/dL',
              color,
            ),
            _metricColumn(
              'Rise',
              '+${(estimatedGlucose!['glucoseRise'] as num).toStringAsFixed(0)}',
              color,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color),
              ),
              child: Text(
                riskLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          estimatedGlucose!['riskDescription'] ?? '',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

Widget _metricColumn(String label, String value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

  Widget _buildNutritionCard() {
  if (estimatedNutrition == null) {
    return const SizedBox.shrink();
  }

  return Container(
    decoration: metricCardDecoration(),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Nutrition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _nutritionStat('Carbs',
              '${estimatedNutrition!['totalCarbs'].toStringAsFixed(1)} g',
              AppColors.carbs),
            _nutritionStat('Protein',
              '${estimatedNutrition!['totalProtein'].toStringAsFixed(1)} g',
              AppColors.protein),
            _nutritionStat('Fat',
              '${estimatedNutrition!['totalFat'].toStringAsFixed(1)} g',
              AppColors.fat),
            _nutritionStat('Calories',
              '${estimatedNutrition!['totalCalories'].toStringAsFixed(0)}',
              AppColors.calories),
          ],
        ),
      ],
    ),
  );
}
Widget _nutritionStat(String label, String value, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
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

  // 🔢 Calorie-based distribution
  final totalCalories = carbs * 4 + protein * 4 + fat * 9;

  final carbsPct = totalCalories > 0 ? (carbs * 4) / totalCalories * 100 : 0.0;
  final proteinPct = totalCalories > 0 ? (protein * 4) / totalCalories * 100 : 0.0;
  final fatPct = totalCalories > 0 ? (fat * 9) / totalCalories * 100 : 0.0;

  return Container(
  margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: AppColors.primaryGradientLight,
    border: Border.all(
      color: AppColors.border.withOpacity(0.6),
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macro Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        _buildMacroBar('Carbs', carbsPct, AppColors.carbs),
        const SizedBox(height: 14),

        _buildMacroBar('Protein', proteinPct, AppColors.protein),
        const SizedBox(height: 14),

        _buildMacroBar('Fat', fatPct, AppColors.fat),
      ],
    ),
  ),
);

}

Widget _macroBar(String label, double percentage, Color color) {
  return _buildMacroBar(label, percentage, color);
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
    elevation: 3,
    shadowColor: const Color(0xFF8D6E63).withOpacity(0.25),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: Color(0xFFD7CCC8),
        width: 1.1,
      ),
    ),
    color: const Color(0xFFF7F4F2),
    child: Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border(
          left: BorderSide(
            color: Color(0xFF8D6E63),
            width: 5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF8D6E63)),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            estimatedGlucose?['recommendations'] as String? ??
                'No specific recommendations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                ),
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
      // Lottie animation for completion
      Center(
        child: Lottie.asset(
          'assets/Complete.json',
          width: 150,
          height: 120,
          fit: BoxFit.cover,
          repeat: false,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Ready to Save',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your meal estimation is complete',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      const SizedBox(height: 24),

      // 🌸 Custom Meal Summary Card
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradientLight,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Meal Type',
                  selectedMealType?.toUpperCase() ?? 'Unknown'),
              _buildSummaryRow('Items', '${selectedFoods.length} foods'),
              _buildSummaryRow(
                  'Total Carbs',
                  '${estimatedNutrition?['totalCarbs']?.toStringAsFixed(1) ?? '0'}g'),
              _buildSummaryRow(
                  'Glucose Peak',
                  '${estimatedGlucose?['estimatedPeakGlucose']?.toStringAsFixed(0) ?? '0'} mg/dL'),
              _buildSummaryRow(
                  'Risk Level',
                  estimatedGlucose?['riskLevel']?.toUpperCase() ?? 'Unknown'),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                side: BorderSide(color: AppColors.border),
              ),
              onPressed: () {
                setState(() {
                  currentStep--;
                  estimatedNutrition = null;
                  estimatedGlucose = null;
                });
              },
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 16, // ⬅ increased
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        if (currentStep > 1) const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.btnPrimary,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.btnDisabled,
              disabledForegroundColor: AppColors.textTertiary,
              elevation: 0,
            ),
            onPressed: _canProceedToNextStep()
                ? () {
                    setState(() => currentStep++);
                    if (currentStep == 4) {
                      _calculateEstimates();
                    }
                  }
                : null,
            child: Text(
              currentStep == 5 ? 'Save' : 'Next',
              style: const TextStyle(
                fontSize: 18, // ⬅ bigger primary CTA
                fontWeight: FontWeight.w700,
              ),
            ),
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
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primary.withOpacity(0.12)
              : Colors.grey.withOpacity(0.08),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.primary
              : AppColors.textTertiary,
        ),
      ),
    );
  }
}
