

import 'package:carbcheck/model/PlateItem.dart';

/// Service for calculating portion sizes based on user selections
/// 
/// Converts user-selected portion sizes (Small/Medium/Large)
/// into actual gram amounts for accurate nutrition calculation
class ServingSizeCalculator {
  /// Portion size multipliers
  /// Used to convert standard serving to actual portion
  static const Map<String, double> portionMultipliers = {
    'Small': 0.67,    // 2/3 of standard serving
    'Medium': 1.0,    // Standard serving (default)
    'Large': 1.5,     // 1.5x standard serving
  };

  /// Default portion size if user doesn't specify
  static const String defaultPortion = 'Medium';

  /// Calculate grams from standard serving size and user selection
  /// 
  /// Formula: grams = standardServingGrams × multiplier × quantity
  /// 
  /// Parameters:
  ///   - standardServingGrams: USDA standard (e.g., 158 for rice)
  ///   - selectedUnit: "Small", "Medium", or "Large"
  ///   - quantity: How many (e.g., 1, 2, 3)
  /// 
  /// Returns: Final gram amount
  /// 
  /// Example:
  /// ```dart
  /// final grams = ServingSizeCalculator.calculateGrams(
  ///   standardServingGrams: 158,  // 1 cup rice
  ///   selectedUnit: 'Large',       // 1.5x
  ///   quantity: 2,                 // 2 servings
  /// );
  /// // grams = 158 × 1.5 × 2 = 474g
  /// ```
  static double calculateGrams({
    required double standardServingGrams,
    required String selectedUnit,
    required int quantity,
  }) {
    // Get multiplier for portion size
    final multiplier = getPortionMultiplier(selectedUnit);
    
    // Calculate: standard × multiplier × quantity
    final grams = standardServingGrams * multiplier * quantity;
    
    // Round to 1 decimal place
    return double.parse(grams.toStringAsFixed(1));
  }

  /// Get portion multiplier for a given size
  /// 
  /// Parameters:
  ///   - portionSize: "Small", "Medium", or "Large"
  /// 
  /// Returns:
  ///   - 0.67 for "Small"
  ///   - 1.0 for "Medium"
  ///   - 1.5 for "Large"
  ///   - 1.0 for unknown (default to Medium)
  static double getPortionMultiplier(String portionSize) {
    return portionMultipliers[portionSize] ?? 1.0;
  }

  /// Get percentage of standard serving
  /// 
  /// Example:
  /// ```dart
  /// getPortionPercentage('Small')   // 67%
  /// getPortionPercentage('Medium')  // 100%
  /// getPortionPercentage('Large')   // 150%
  /// ```
  static int getPortionPercentage(String portionSize) {
    final multiplier = getPortionMultiplier(portionSize);
    return (multiplier * 100).toInt();
  }

  /// Get human-readable portion description
  /// 
  /// Example:
  /// ```dart
  /// getPortionDescription('Small')   // "Small (67%)"
  /// getPortionDescription('Medium')  // "Medium (100%)"
  /// getPortionDescription('Large')   // "Large (150%)"
  /// ```
  static String getPortionDescription(String portionSize) {
    final percentage = getPortionPercentage(portionSize);
    return '$portionSize ($percentage%)';
  }

  /// Validate portion size
  /// 
  /// Returns true if portion size is valid (Small, Medium, or Large)
  static bool isValidPortion(String portionSize) {
    return portionMultipliers.containsKey(portionSize);
  }

  /// Validate quantity
  /// 
  /// Returns true if quantity is positive
  static bool isValidQuantity(int quantity) {
    return quantity > 0;
  }

  /// Get all valid portion sizes
  static List<String> getValidPortions() {
    return portionMultipliers.keys.toList();
  }

  /// Calculate total portions
  /// 
  /// Example:
  /// ```dart
  /// calculateTotalPortions(
  ///   selectedUnit: 'Medium',
  ///   quantity: 2,
  /// );
  /// // Returns 2.0 (2 × Medium = 2 full servings)
  /// ```
  static double calculateTotalPortions(
    String selectedUnit,
    int quantity,
  ) {
    final multiplier = getPortionMultiplier(selectedUnit);
    return multiplier * quantity;
  }

  /// Get comparison string between portion sizes
  /// 
  /// Example:
  /// ```dart
  /// getComparisonString(158, 'Medium', 'Large');
  /// // Returns: "Medium (158g) vs Large (237g)"
  /// ```
  static String getComparisonString(
    double standardGrams,
    String portion1,
    String portion2,
  ) {
    final grams1 = standardGrams * getPortionMultiplier(portion1);
    final grams2 = standardGrams * getPortionMultiplier(portion2);
    
    return '$portion1 (${grams1.toStringAsFixed(0)}g) vs '
        '$portion2 (${grams2.toStringAsFixed(0)}g)';
  }

  /// Get all portion options with grams
  /// 
  /// Returns map of portion size to grams
  /// 
  /// Example:
  /// ```dart
  /// getPortionOptions(182);
  /// // Returns: {
  /// //   'Small': 121.94,
  /// //   'Medium': 182.0,
  /// //   'Large': 273.0,
  /// // }
  /// ```
  static Map<String, double> getPortionOptions(double standardGrams) {
    final options = <String, double>{};
    for (var entry in portionMultipliers.entries) {
      options[entry.key] = standardGrams * entry.value;
    }
    return options;
  }

  /// Update PlateItem with calculated grams
  /// 
  /// Convenience method that calculates grams and returns updated PlateItem
  /// 
  /// Example:
  /// ```dart
  /// final item = updatePlateItemGrams(
  ///   item: plateItem,
  ///   standardServingGrams: 158,
  /// );
  /// // Returns item with portionInGrams updated
  /// ```
  static PlateItem updatePlateItemGrams(
    PlateItem item, {
    required double standardServingGrams,
  }) {
    final grams = calculateGrams(
      standardServingGrams: standardServingGrams,
      selectedUnit: item.selectedUnit,
      quantity: item.quantity,
    );

    return item.copyWith(portionInGrams: grams);
  }

  /// Get portion adjustment factor
  /// 
  /// Used to adjust from one portion to another
  /// 
  /// Example:
  /// ```dart
  /// getAdjustmentFactor('Small', 'Large');
  /// // Returns 2.238 (Large is 2.238x Small)
  /// ```
  static double getAdjustmentFactor(String fromPortion, String toPortion) {
    final fromMultiplier = getPortionMultiplier(fromPortion);
    final toMultiplier = getPortionMultiplier(toPortion);
    
    if (fromMultiplier == 0) return 1.0;
    return toMultiplier / fromMultiplier;
  }

  /// Validate portion calculation
  /// 
  /// Returns null if valid, error message if invalid
  static String? validateCalculation({
    required double standardServingGrams,
    required String selectedUnit,
    required int quantity,
  }) {
    if (standardServingGrams <= 0) {
      return 'Standard serving must be greater than 0';
    }
    if (!isValidPortion(selectedUnit)) {
      return 'Invalid portion size: $selectedUnit';
    }
    if (!isValidQuantity(quantity)) {
      return 'Quantity must be greater than 0';
    }
    return null;
  }

  /// Get recommended portions for different scenarios
  /// 
  /// Example:
  /// ```dart
  /// getRecommendedPortions(diabetic: true);
  /// // Returns ['Small', 'Medium']  // Skip Large for diabetics
  /// ```
  static List<String> getRecommendedPortions({
    bool diabetic = false,
    bool lowCalorie = false,
  }) {
    if (diabetic) {
      return ['Small', 'Medium']; // Avoid large portions
    }
    if (lowCalorie) {
      return ['Small', 'Medium']; // Focus on smaller portions
    }
    return ['Small', 'Medium', 'Large']; // All options
  }
}

/// Extended calculator for batch operations
extension ServingSizeCalculatorBatch on ServingSizeCalculator {
  /// Calculate grams for multiple foods at once
  /// 
  /// Parameters:
  ///   - foods: List of maps with standard serving and portion info
  /// 
  /// Returns: List of calculated gram amounts
  /// 
  /// Example:
  /// ```dart
  /// final foods = [
  ///   {'standard': 158, 'portion': 'Medium', 'qty': 1}, // rice
  ///   {'standard': 182, 'portion': 'Large', 'qty': 2},  // apples
  /// ];
  /// 
  /// final results = ServingSizeCalculator.batchCalculate(foods);
  /// // [158, 546]
  /// ```
  static List<double> batchCalculate(
    List<Map<String, dynamic>> foods,
  ) {
    return foods.map((food) {
      return ServingSizeCalculator.calculateGrams(
        standardServingGrams: food['standard'] as double,
        selectedUnit: food['portion'] as String,
        quantity: food['qty'] as int,
      );
    }).toList();
  }

  /// Calculate average portion size from list
  static double calculateAveragePortion(List<double> portions) {
    if (portions.isEmpty) return 0;
    final sum = portions.fold<double>(0, (a, b) => a + b);
    return sum / portions.length;
  }

  /// Compare multiple portion options
  static Map<String, double> comparePortion(double standardGrams) {
    return ServingSizeCalculator.getPortionOptions(standardGrams);
  }
}
