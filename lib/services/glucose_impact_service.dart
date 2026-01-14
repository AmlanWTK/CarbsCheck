

import 'package:carbcheck/model/glucose_models.dart';
import 'package:carbcheck/model/nutrition_models.dart';

/// Service for estimating glucose impact from meals
/// 
/// Calculates predicted glucose peaks and risk levels based on:
/// - Patient's carbohydrate sensitivity
/// - Meal carbohydrate content
/// - Current baseline glucose
class GlucoseImpactService {
  /// Default carbohydrate sensitivity if not provided
  /// mg/dL rise per 10g of carbs (population average)
  static const double defaultSensitivity = 12.0;

  /// Estimate glucose impact from food nutrition
  /// 
  /// Calculates peak glucose and risk level based on carbs consumed
  /// 
  /// Formula:
  /// ```
  /// Glucose Rise = (Carbs ÷ 10) × Glucose Sensitivity
  /// Peak Glucose = Baseline + Glucose Rise
  /// ```
  /// 
  /// Parameters:
  ///   - nutrition: FoodNutritionDetail with carb content
  ///   - baselineGlucose: Current glucose level (e.g., 105 mg/dL)
  ///   - glucoseSensitivity: mg/dL rise per 10g carbs (default: 12.0)
  /// 
  /// Returns: GlucoseImpactEstimate with peak, rise, and risk
  /// 
  /// Example:
  /// ```dart
  /// final impact = service.estimateFoodImpact(
  ///   nutrition: riceNutrition,     // 44.2g carbs
  ///   baselineGlucose: 105,
  ///   glucoseSensitivity: 12.0,
  /// );
  /// // Peak: 160 mg/dL (+55 rise) - Medium Risk
  /// ```
  GlucoseImpactEstimate estimateFoodImpact({
    required FoodNutritionDetail nutrition,
    required double baselineGlucose,
    double? glucoseSensitivity,
  }) {
    final sensitivity = glucoseSensitivity ?? defaultSensitivity;

    print('📊 Calculating glucose impact for: ${nutrition.foodName}');
    print('   Baseline: ${baselineGlucose.toStringAsFixed(0)} mg/dL');
    print('   Carbs: ${nutrition.carbs.toStringAsFixed(1)}g');
    print('   Sensitivity: $sensitivity');

    // Step 1: Calculate glucose rise
    final glucoseRise = calculateGlucoseRise(
      carbs: nutrition.carbs,
      sensitivity: sensitivity,
    );

    // Step 2: Calculate peak glucose
    final estimatedPeakGlucose = baselineGlucose + glucoseRise;

    // Step 3: Determine risk level
    final riskLevel = determineRiskLevel(glucoseRise);

    // Step 4: Get risk description
    final riskDescription = getRiskDescription(
      glucoseRise: glucoseRise,
      carbs: nutrition.carbs,
      riskLevel: riskLevel,
    );

    final estimate = GlucoseImpactEstimate(
      baselineGlucose: baselineGlucose,
      estimatedPeakGlucose: estimatedPeakGlucose,
      glucoseRise: glucoseRise,
      riskLevel: riskLevel,
      riskDescription: riskDescription,
      mealCarbs: nutrition.carbs,
      glucoseSensitivity: sensitivity,
      calculatedAt: DateTime.now(),
      recommendations: getRecommendations(
        carbs: nutrition.carbs,
        glucoseRise: glucoseRise,
        riskLevel: riskLevel,
      ),
    );

    print('✅ Glucose Impact:');
    print('   Peak: ${estimate.estimatedPeakGlucose.toStringAsFixed(0)} mg/dL '
        '(+${estimate.glucoseRise.toStringAsFixed(0)})');
    print('   Risk: ${estimate.riskLevel}');
    print('   ${estimate.riskDescription}');

    return estimate;
  }

  /// Estimate glucose impact from complete meal
  /// 
  /// Combines multiple foods and calculates total glucose impact
  /// 
  /// Example:
  /// ```dart
  /// final impact = service.estimateMealImpact(
  ///   items: [riceNutrition, chickenNutrition],
  ///   baselineGlucose: 105,
  ///   glucoseSensitivity: 12.0,
  /// );
  /// ```
  GlucoseImpactEstimate estimateMealImpact({
    required List<FoodNutritionDetail> items,
    required double baselineGlucose,
    double? glucoseSensitivity,
  }) {
    if (items.isEmpty) {
      print('⚠️ No items to estimate glucose impact');
      return GlucoseImpactEstimate(
        baselineGlucose: baselineGlucose,
        estimatedPeakGlucose: baselineGlucose,
        glucoseRise: 0,
        riskLevel: 'low',
        riskDescription: 'No food - no glucose impact',
        mealCarbs: 0,
        glucoseSensitivity: glucoseSensitivity ?? defaultSensitivity,
        calculatedAt: DateTime.now(),
      );
    }

    // Sum carbs from all items
    final totalCarbs = items.fold<double>(0, (sum, item) => sum + item.carbs);

    print('📊 Calculating meal glucose impact for ${items.length} foods');
    print('   Total carbs: ${totalCarbs.toStringAsFixed(1)}g');

    final sensitivity = glucoseSensitivity ?? defaultSensitivity;

    // Calculate glucose rise from total carbs
    final glucoseRise = calculateGlucoseRise(
      carbs: totalCarbs,
      sensitivity: sensitivity,
    );

    final estimatedPeakGlucose = baselineGlucose + glucoseRise;
    final riskLevel = determineRiskLevel(glucoseRise);

    final estimate = GlucoseImpactEstimate(
      baselineGlucose: baselineGlucose,
      estimatedPeakGlucose: estimatedPeakGlucose,
      glucoseRise: glucoseRise,
      riskLevel: riskLevel,
      riskDescription: getRiskDescription(
        glucoseRise: glucoseRise,
        carbs: totalCarbs,
        riskLevel: riskLevel,
      ),
      mealCarbs: totalCarbs,
      glucoseSensitivity: sensitivity,
      calculatedAt: DateTime.now(),
      recommendations: getRecommendations(
        carbs: totalCarbs,
        glucoseRise: glucoseRise,
        riskLevel: riskLevel,
      ),
    );

    print('✅ Meal glucose impact:');
    print('   Peak: ${estimate.estimatedPeakGlucose.toStringAsFixed(0)} mg/dL '
        '(+${estimate.glucoseRise.toStringAsFixed(0)})');
    print('   Risk: ${estimate.riskLevel}');

    return estimate;
  }

  /// Calculate glucose rise from carbohydrate content
  /// 
  /// Formula: rise = (carbs ÷ 10) × sensitivity
  /// 
  /// Parameters:
  ///   - carbs: Grams of carbohydrates
  ///   - sensitivity: mg/dL rise per 10g carbs
  /// 
  /// Returns: Estimated glucose rise in mg/dL
  /// 
  /// Example:
  /// ```dart
  /// final rise = service.calculateGlucoseRise(
  ///   carbs: 44.2,
  ///   sensitivity: 12.0,
  /// );
  /// // Returns: 53.04 mg/dL
  /// ```
  static double calculateGlucoseRise({
    required double carbs,
    required double sensitivity,
  }) {
    // Formula: carbs / 10 × sensitivity
    final rise = (carbs / 10) * sensitivity;
    return double.parse(rise.toStringAsFixed(1));
  }

  /// Determine risk level from glucose rise
  /// 
  /// Risk Categories:
  /// - "low": rise < 40 mg/dL (safe)
  /// - "medium": rise 40-80 mg/dL (acceptable)
  /// - "high": rise > 80 mg/dL (caution needed)
  /// 
  /// Parameters:
  ///   - glucoseRise: Estimated glucose rise in mg/dL
  /// 
  /// Returns: Risk level string ("low", "medium", "high")
  static String determineRiskLevel(double glucoseRise) {
    if (glucoseRise < 40) {
      return 'low';
    } else if (glucoseRise <= 80) {
      return 'medium';
    } else {
      return 'high';
    }
  }

  /// Get human-readable risk description
  /// 
  /// Example return values:
  /// - "Low rise (30 mg/dL) - Safe"
  /// - "Medium rise (52 mg/dL) - Acceptable"
  /// - "High rise (105 mg/dL) - High carbs, consider smaller portion"
  static String getRiskDescription({
    required double glucoseRise,
    required double carbs,
    required String riskLevel,
  }) {
    final riseStr = glucoseRise.toStringAsFixed(0);
    final carbsStr = carbs.toStringAsFixed(1);

    switch (riskLevel) {
      case 'low':
        return 'Low rise ($riseStr mg/dL) - Safe for most';
      case 'medium':
        return 'Medium rise ($riseStr mg/dL) - Acceptable intake';
      case 'high':
        return 'High rise ($riseStr mg/dL) - High carbs ($carbsStr g), '
            'consider smaller portion or pairing with protein';
      default:
        return 'Unknown risk level';
    }
  }

  
  static String? getRecommendations({
    required double carbs,
    required double glucoseRise,
    required String riskLevel,
  }) {
    switch (riskLevel) {
      case 'low':
        if (carbs < 15) {
          return 'Low carb content - good choice for blood sugar control';
        }
        return 'Acceptable portion - monitor effects';

      case 'medium':
        if (carbs > 50) {
          return 'Pair with protein or fat to slow absorption';
        }
        return 'Moderate carbs - pair with fiber or protein';

      case 'high':
        if (carbs > 80) {
          return 'Very high carbs - strongly consider reducing portion by 1/3 '
              'and adding protein/vegetables';
        }
        if (glucoseRise > 100) {
          return 'High glycemic impact - eat smaller portions and pair with protein';
        }
        return 'Consider skipping or reducing to Small portion';

      default:
        return null;
    }
  }

  /// Compare glucose impact of different portions
  /// 
  /// Example:
  /// ```dart
  /// final comparison = service.comparePortion(
  ///   carbs: 44.2,
  ///   baselineGlucose: 105,
  ///   portions: [100, 158, 237],
  /// );
  /// // Returns map with impact for each portion
  /// ```
  Map<double, GlucoseImpactEstimate> comparePortion({
    required double carbs,
    required double baselineGlucose,
    required List<double> portions,
    double? glucoseSensitivity,
  }) {
    final sensitivity = glucoseSensitivity ?? defaultSensitivity;
    final results = <double, GlucoseImpactEstimate>{};

    for (var portion in portions) {
      // Scale carbs proportionally
      final scaledCarbs = carbs * (portion / 158.0); // 158g is standard

      final glucoseRise = calculateGlucoseRise(
        carbs: scaledCarbs,
        sensitivity: sensitivity,
      );

      final estimate = GlucoseImpactEstimate(
        baselineGlucose: baselineGlucose,
        estimatedPeakGlucose: baselineGlucose + glucoseRise,
        glucoseRise: glucoseRise,
        riskLevel: determineRiskLevel(glucoseRise),
        riskDescription: getRiskDescription(
          glucoseRise: glucoseRise,
          carbs: scaledCarbs,
          riskLevel: determineRiskLevel(glucoseRise),
        ),
        mealCarbs: scaledCarbs,
        glucoseSensitivity: sensitivity,
        calculatedAt: DateTime.now(),
      );

      results[portion] = estimate;
    }

    return results;
  }

  static int calculateTimeToPeak({
    required double carbs,
    String foodType = 'complex',
  }) {
    // Base time depends on food type
    int baseTime;
    switch (foodType.toLowerCase()) {
      case 'simple':
        baseTime = 20;
        break;
      case 'complex':
        baseTime = 35;
        break;
      case 'mixed':
        baseTime = 50;
        break;
      default:
        baseTime = 45;
    }

    // Adjust based on carb amount (more carbs = longer digestion)
    final adjustment = (carbs / 50) * 10; // +10 minutes per 50g carbs
    return (baseTime + adjustment).toInt();
  }

  /// Get safe glucose threshold
  /// 
  /// Returns maximum peak glucose before it's considered unsafe
  /// Typical safe threshold: 180 mg/dL (ADA guidelines)
  /// Normal target: 140 mg/dL (good control)
  /// 
  /// Parameters:
  ///   - diabetesType: "type1", "type2", "gestational"
  /// 
  /// Returns: Safe glucose threshold
  static double getSafeThreshold(String? diabetesType) {
    switch (diabetesType?.toLowerCase()) {
      case 'type1':
        return 180; // Insulin-dependent
      case 'type2':
        return 180; // More forgiving
      case 'gestational':
        return 160; // More strict
      default:
        return 180; // ADA standard
    }
  }

  /// Get target glucose range
  /// 
  /// Parameters:
  ///   - diabetesType: Type of diabetes
  /// 
  /// Returns: Map with 'min' and 'max' targets
  static Map<String, double> getTargetRange(String? diabetesType) {
    switch (diabetesType?.toLowerCase()) {
      case 'type1':
        return {'min': 100.0, 'max': 140.0};
      case 'type2':
        return {'min': 100.0, 'max': 150.0};
      case 'gestational':
        return {'min': 95.0, 'max': 140.0};
      default:
        return {'min': 100.0, 'max': 140.0};
    }
  }

  /// Check if glucose impact is within safe range
  /// 
  /// Parameters:
  ///   - estimate: GlucoseImpactEstimate to check
  ///   - safeThreshold: Maximum safe glucose (default: 180)
  /// 
  /// Returns: true if peak is below threshold
  static bool isSafeGlucoseLevel(
    GlucoseImpactEstimate estimate, {
    double safeThreshold = 180,
  }) {
    return estimate.estimatedPeakGlucose < safeThreshold;
  }

  /// Check if glucose impact is in target range
  /// 
  /// Parameters:
  ///   - estimate: GlucoseImpactEstimate to check
  ///   - minTarget: Minimum target glucose
  ///   - maxTarget: Maximum target glucose
  /// 
  /// Returns: true if peak is within range
  static bool isInTargetRange(
    GlucoseImpactEstimate estimate, {
    required double minTarget,
    required double maxTarget,
  }) {
    return estimate.estimatedPeakGlucose >= minTarget &&
        estimate.estimatedPeakGlucose <= maxTarget;
  }

  /// Get color recommendation for UI display
  /// 
  /// Returns color based on glucose impact:
  /// - "green" for safe/low risk
  /// - "amber" for medium risk
  /// - "red" for high risk/dangerous
  static String getColorForRisk(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'green';
      case 'medium':
        return 'amber';
      case 'high':
        return 'red';
      default:
        return 'gray';
    }
  }

  /// Validate glucose impact estimate
  /// 
  /// Returns null if valid, error message if invalid
  static String? validateEstimate(GlucoseImpactEstimate estimate) {
    if (estimate.baselineGlucose < 0) {
      return 'Baseline glucose must be >= 0';
    }
    if (estimate.estimatedPeakGlucose < estimate.baselineGlucose) {
      return 'Peak cannot be less than baseline';
    }
    if (estimate.glucoseRise < 0) {
      return 'Glucose rise must be >= 0';
    }
    if (estimate.glucoseSensitivity <= 0) {
      return 'Glucose sensitivity must be > 0';
    }
    if (estimate.mealCarbs < 0) {
      return 'Meal carbs must be >= 0';
    }
    if (!['low', 'medium', 'high'].contains(estimate.riskLevel.toLowerCase())) {
      return 'Invalid risk level: ${estimate.riskLevel}';
    }
    return null;
  }

  /// Get tips for managing glucose impact
  /// 
  /// Returns list of evidence-based strategies
  static List<String> getManagementTips() {
    return [
      '✓ Pair carbs with protein or fat to slow absorption',
      '✓ Eat vegetables before carbs to improve glucose response',
      '✓ Stay hydrated - affects glucose metabolism',
      '✓ Walk 10-15 minutes after eating to lower peak glucose',
      '✓ Choose complex carbs over simple sugars',
      '✓ Eat smaller portions more frequently',
      '✓ Maintain consistent meal times',
      '✓ Exercise regularly improves insulin sensitivity',
      '✓ Manage stress - cortisol affects glucose',
      '✓ Get adequate sleep - improves glucose control',
    ];
  }
}

/// Risk assessment helper for detailed analysis
class GlucoseRiskAssessment {
  /// Assess overall glucose control risk
  /// 
  /// Takes into account multiple factors
  static String assessOverallRisk({
    required List<GlucoseImpactEstimate> estimates,
    required double targetMin,
    required double targetMax,
  }) {
    if (estimates.isEmpty) return 'No data';

    final highs = estimates.where((e) => e.riskLevel == 'high').length;
    final mediums = estimates.where((e) => e.riskLevel == 'medium').length;

    if (highs > estimates.length / 2) {
      return 'High risk - multiple meals with high glucose impact';
    } else if (highs > 0) {
      return 'Moderate risk - some meals with high glucose impact';
    } else if (mediums > estimates.length / 2) {
      return 'Low-moderate risk - mostly medium impact meals';
    } else {
      return 'Low risk - good glucose control';
    }
  }

  /// Get detailed risk breakdown
  static Map<String, int> getRiskBreakdown(
    List<GlucoseImpactEstimate> estimates,
  ) {
    return {
      'low': estimates.where((e) => e.riskLevel == 'low').length,
      'medium': estimates.where((e) => e.riskLevel == 'medium').length,
      'high': estimates.where((e) => e.riskLevel == 'high').length,
    };
  }

  /// Get average glucose impact
  static double getAverageGlucoseRise(
    List<GlucoseImpactEstimate> estimates,
  ) {
    if (estimates.isEmpty) return 0;
    final sum = estimates.fold<double>(0, (sum, e) => sum + e.glucoseRise);
    return sum / estimates.length;
  }
}
