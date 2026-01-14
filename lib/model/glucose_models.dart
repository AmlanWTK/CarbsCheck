import 'package:equatable/equatable.dart';

/// Represents an estimated glucose impact from a meal
/// 
/// Contains the predicted glucose peak, impact level, and risk assessment
/// for diabetes patients based on their glucose sensitivity
class GlucoseImpactEstimate with EquatableMixin {
  /// Current baseline glucose level (before meal)
  /// Measured in mg/dL
  /// Example: 105 mg/dL (normal fasting range: 70-100)
  final double baselineGlucose;

  /// Estimated peak glucose level after this meal
  /// Measured in mg/dL
  /// Formula: baselineGlucose + carbs * glucoseSensitivity / 10
  /// Example: 158 mg/dL (safe range: < 180)
  final double estimatedPeakGlucose;

  /// Expected glucose rise from this meal
  /// Calculated as: estimatedPeakGlucose - baselineGlucose
  /// Example: 53 mg/dL rise
  final double glucoseRise;

  /// Risk level categorization
  /// One of: "low", "medium", "high"
  /// - "low": rise < 40 mg/dL (safe)
  /// - "medium": rise 40-80 mg/dL (acceptable)
  /// - "high": rise > 80 mg/dL (caution needed)
  final String riskLevel;

  /// Human-readable description of the risk
  /// Examples:
  /// - "Low rise (30 mg/dL) - Safe"
  /// - "Medium rise (52 mg/dL) - Acceptable"
  /// - "High rise (105 mg/dL) - High carbs, consider smaller portion"
  final String riskDescription;

  /// Total carbohydrates in the meal that led to this estimate
  /// Used for reference and logging
  final double mealCarbs;

  /// Patient's glucose sensitivity
  /// mg/dL rise per 10g of carbs
  /// Default: 12 (standard, varies by patient)
  /// Calculated: (previous rise) / (carbs) * 10
  final double glucoseSensitivity;

  /// Time this estimate was calculated
  final DateTime? calculatedAt;

  /// Additional notes or recommendations
  /// Examples:
  /// - "Pair with protein for slower absorption"
  /// - "Consider exercise 30 min after meal"
  /// - "High carbs - consider skipping dessert"
  final String? recommendations;

  /// Constructor
  GlucoseImpactEstimate({
    required this.baselineGlucose,
    required this.estimatedPeakGlucose,
    required this.glucoseRise,
    required this.riskLevel,
    required this.riskDescription,
    required this.mealCarbs,
    required this.glucoseSensitivity,
    this.calculatedAt,
    this.recommendations,
  });

  /// Create a copy with optional field changes
  GlucoseImpactEstimate copyWith({
    double? baselineGlucose,
    double? estimatedPeakGlucose,
    double? glucoseRise,
    String? riskLevel,
    String? riskDescription,
    double? mealCarbs,
    double? glucoseSensitivity,
    DateTime? calculatedAt,
    String? recommendations,
  }) {
    return GlucoseImpactEstimate(
      baselineGlucose: baselineGlucose ?? this.baselineGlucose,
      estimatedPeakGlucose: estimatedPeakGlucose ?? this.estimatedPeakGlucose,
      glucoseRise: glucoseRise ?? this.glucoseRise,
      riskLevel: riskLevel ?? this.riskLevel,
      riskDescription: riskDescription ?? this.riskDescription,
      mealCarbs: mealCarbs ?? this.mealCarbs,
      glucoseSensitivity: glucoseSensitivity ?? this.glucoseSensitivity,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  /// Convert to JSON for backend transmission
  Map<String, dynamic> toJson() => {
    'baselineGlucose': baselineGlucose,
    'estimatedPeakGlucose': estimatedPeakGlucose,
    'glucoseRise': glucoseRise,
    'riskLevel': riskLevel,
    'riskDescription': riskDescription,
    'mealCarbs': mealCarbs,
    'glucoseSensitivity': glucoseSensitivity,
    'calculatedAt': calculatedAt?.toIso8601String(),
    'recommendations': recommendations,
  };

  /// Create from JSON (from backend or storage)
  factory GlucoseImpactEstimate.fromJson(Map<String, dynamic> json) {
    return GlucoseImpactEstimate(
      baselineGlucose: (json['baselineGlucose'] as num).toDouble(),
      estimatedPeakGlucose: (json['estimatedPeakGlucose'] as num).toDouble(),
      glucoseRise: (json['glucoseRise'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
      riskDescription: json['riskDescription'] as String,
      mealCarbs: (json['mealCarbs'] as num).toDouble(),
      glucoseSensitivity: (json['glucoseSensitivity'] as num).toDouble(),
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : null,
      recommendations: json['recommendations'] as String?,
    );
  }

  /// Get a summary string for UI display
  /// 
  /// Example: "Peak: 158 mg/dL (+53) - Medium Risk"
  String getSummaryString() {
    return 'Peak: ${estimatedPeakGlucose.toStringAsFixed(0)} mg/dL '
        '(+${glucoseRise.toStringAsFixed(0)}) - ${_capitalizeFirst(riskLevel)} Risk';
  }

  /// Get color recommendation for UI
  /// 
  /// Returns:
  /// - "green" for low risk
  /// - "amber" for medium risk
  /// - "red" for high risk
  String getColorByRisk() {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return 'green';
      case 'high':
        return 'red';
      case 'medium':
      default:
        return 'amber';
    }
  }

  /// Check if glucose is in safe range
  /// 
  /// Safe range: < 180 mg/dL (ADA recommendations)
  bool isSafeRange() => estimatedPeakGlucose < 180;

  /// Check if glucose is in normal range
  /// 
  /// Normal range: 70-140 mg/dL (good control)
  bool isNormalRange() => estimatedPeakGlucose >= 70 && estimatedPeakGlucose <= 140;

  /// Check if glucose is in danger zone
  /// 
  /// Danger zone: > 200 mg/dL (immediate concern)
  bool isDangerZone() => estimatedPeakGlucose > 200;

  /// Helper method to capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Check if data is valid
  /// 
  /// Returns true if:
  /// - All glucose values >= 0
  /// - Peak >= baseline
  /// - Sensitivity > 0
  /// - Risk level is valid
  bool isValid() {
    final validRisks = ['low', 'medium', 'high'];
    return baselineGlucose >= 0 &&
        estimatedPeakGlucose >= baselineGlucose &&
        glucoseRise >= 0 &&
        validRisks.contains(riskLevel.toLowerCase()) &&
        glucoseSensitivity > 0 &&
        mealCarbs >= 0;
  }

  @override
  List<Object?> get props => [
    baselineGlucose,
    estimatedPeakGlucose,
    glucoseRise,
    riskLevel,
    riskDescription,
    mealCarbs,
    glucoseSensitivity,
    calculatedAt,
    recommendations,
  ];

  @override
  String toString() {
    return 'GlucoseImpactEstimate('
        'baseline: $baselineGlucose, '
        'peak: $estimatedPeakGlucose, '
        'rise: $glucoseRise, '
        'risk: $riskLevel)';
  }
}

/// Represents patient's glucose profile and sensitivity
/// 
/// Contains patient-specific glucose response patterns
/// and thresholds for personalized meal recommendations
class PatientGlucoseProfile with EquatableMixin {
  /// Patient's unique identifier
  final String? patientId;

  /// Patient's carb sensitivity factor
  /// mg/dL rise per 10g of carbs
  /// Default: 12.0 (population average)
  /// Ranges typically: 8-20 (varies by individual)
  /// 
  /// Calculated from: (observed glucose rise) / (carbs) * 10
  /// Example:
  /// - Patient ate 50g carbs
  /// - Glucose rose from 105 to 160 (55 mg/dL rise)
  /// - Sensitivity = 55 / 50 * 10 = 11.0
  final double carbSensitivity;

  /// Patient's target glucose range (lower bound)
  /// mg/dL
  /// Default: 100 (below 100 is fasting goal)
  final double targetGlucoseMin;

  /// Patient's target glucose range (upper bound)
  /// mg/dL
  /// Default: 140 (post-meal safe limit)
  final double targetGlucoseMax;

  /// Absolute maximum glucose threshold (alarm point)
  /// mg/dL
  /// Default: 180 (danger zone begins)
  /// Beyond this = needs intervention
  final double maxGlucoseThreshold;

  /// Latest baseline glucose reading
  /// Used for estimating meal impact
  /// Updated whenever new glucose reading comes in
  final double currentGlucose;

  /// Time of last glucose reading
  /// Track how recent the baseline is
  final DateTime? lastGlucoseReadingTime;

  /// Flag to indicate if glucose data is from
  /// a recent reading (< 15 min)
  final bool isRecentReading;

  /// Patient's diabetes type
  /// "type1", "type2", "gestational", etc.
  /// Affects recommendations
  final String? diabetesType;

  /// Average daily activity level
  /// 1-5 scale (affects sensitivity calculation)
  /// 1: sedentary, 5: very active
  final int? activityLevel;

  /// Timestamp when profile was created/updated
  final DateTime? createdAt;

  /// Notes or additional info about patient
  /// Examples:
  /// - "Very sensitive to carbs after 6pm"
  /// - "Sensitivity varies by food type"
  /// - "Exercise 2h after meals"
  final String? notes;

  /// Constructor
  PatientGlucoseProfile({
    this.patientId,
    required this.carbSensitivity,
    required this.targetGlucoseMin,
    required this.targetGlucoseMax,
    required this.maxGlucoseThreshold,
    required this.currentGlucose,
    this.lastGlucoseReadingTime,
    required this.isRecentReading,
    this.diabetesType,
    this.activityLevel,
    this.createdAt,
    this.notes,
  });

  /// Factory constructor with sensible defaults
  /// 
  /// Uses standard diabetes care thresholds
  factory PatientGlucoseProfile.withDefaults({
    String? patientId,
    double? carbSensitivity,
    double? targetGlucoseMin,
    double? targetGlucoseMax,
    double? maxGlucoseThreshold,
    required double currentGlucose,
  }) {
    return PatientGlucoseProfile(
      patientId: patientId,
      carbSensitivity: carbSensitivity ?? 12.0,
      targetGlucoseMin: targetGlucoseMin ?? 100.0,
      targetGlucoseMax: targetGlucoseMax ?? 140.0,
      maxGlucoseThreshold: maxGlucoseThreshold ?? 180.0,
      currentGlucose: currentGlucose,
      isRecentReading: true,
    );
  }

  /// Create a copy with optional field changes
  PatientGlucoseProfile copyWith({
    String? patientId,
    double? carbSensitivity,
    double? targetGlucoseMin,
    double? targetGlucoseMax,
    double? maxGlucoseThreshold,
    double? currentGlucose,
    DateTime? lastGlucoseReadingTime,
    bool? isRecentReading,
    String? diabetesType,
    int? activityLevel,
    DateTime? createdAt,
    String? notes,
  }) {
    return PatientGlucoseProfile(
      patientId: patientId ?? this.patientId,
      carbSensitivity: carbSensitivity ?? this.carbSensitivity,
      targetGlucoseMin: targetGlucoseMin ?? this.targetGlucoseMin,
      targetGlucoseMax: targetGlucoseMax ?? this.targetGlucoseMax,
      maxGlucoseThreshold: maxGlucoseThreshold ?? this.maxGlucoseThreshold,
      currentGlucose: currentGlucose ?? this.currentGlucose,
      lastGlucoseReadingTime: lastGlucoseReadingTime ?? this.lastGlucoseReadingTime,
      isRecentReading: isRecentReading ?? this.isRecentReading,
      diabetesType: diabetesType ?? this.diabetesType,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for backend transmission
  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'carbSensitivity': carbSensitivity,
    'targetGlucoseMin': targetGlucoseMin,
    'targetGlucoseMax': targetGlucoseMax,
    'maxGlucoseThreshold': maxGlucoseThreshold,
    'currentGlucose': currentGlucose,
    'lastGlucoseReadingTime': lastGlucoseReadingTime?.toIso8601String(),
    'isRecentReading': isRecentReading,
    'diabetesType': diabetesType,
    'activityLevel': activityLevel,
    'createdAt': createdAt?.toIso8601String(),
    'notes': notes,
  };

  /// Create from JSON (from backend or storage)
  factory PatientGlucoseProfile.fromJson(Map<String, dynamic> json) {
    return PatientGlucoseProfile(
      patientId: json['patientId'] as String?,
      carbSensitivity: (json['carbSensitivity'] as num).toDouble(),
      targetGlucoseMin: (json['targetGlucoseMin'] as num).toDouble(),
      targetGlucoseMax: (json['targetGlucoseMax'] as num).toDouble(),
      maxGlucoseThreshold: (json['maxGlucoseThreshold'] as num).toDouble(),
      currentGlucose: (json['currentGlucose'] as num).toDouble(),
      lastGlucoseReadingTime: json['lastGlucoseReadingTime'] != null
          ? DateTime.parse(json['lastGlucoseReadingTime'] as String)
          : null,
      isRecentReading: json['isRecentReading'] as bool,
      diabetesType: json['diabetesType'] as String?,
      activityLevel: json['activityLevel'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// Get sensitivity with activity adjustment
  /// 
  /// Higher activity = lower sensitivity (can handle more carbs)
  /// Lower activity = higher sensitivity (less tolerance)
  /// 
  /// Adjustment: sensitivity * (6 - activityLevel) / 5
  double getAdjustedSensitivity() {
    if (activityLevel == null) return carbSensitivity;
    final adjustment = (6 - activityLevel!) / 5.0;
    return carbSensitivity * adjustment;
  }

  /// Get a summary string
  /// 
  /// Example: "Target: 100-140 mg/dL | Sensitivity: 12.0 | Current: 105"
  String getSummaryString() {
    return 'Target: ${targetGlucoseMin.toStringAsFixed(0)}-'
        '${targetGlucoseMax.toStringAsFixed(0)} mg/dL | '
        'Sensitivity: ${carbSensitivity.toStringAsFixed(1)} | '
        'Current: ${currentGlucose.toStringAsFixed(0)}';
  }

  /// Check if current glucose is in target range
  bool isInTargetRange() => currentGlucose >= targetGlucoseMin &&
      currentGlucose <= targetGlucoseMax;

  /// Check if current glucose is in safe range
  bool isInSafeRange() => currentGlucose < maxGlucoseThreshold;

  /// Check if reading is stale (> 15 minutes old)
  bool isStaleReading() {
    if (lastGlucoseReadingTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(lastGlucoseReadingTime!);
    return diff.inMinutes > 15;
  }

  /// Check if profile data is valid
  /// 
  /// Returns true if:
  /// - Min < Max targets
  /// - Max < threshold
  /// - Sensitivity > 0
  /// - All glucose values >= 0
  bool isValid() {
    return carbSensitivity > 0 &&
        targetGlucoseMin < targetGlucoseMax &&
        targetGlucoseMax < maxGlucoseThreshold &&
        currentGlucose >= 0;
  }

  @override
  List<Object?> get props => [
    patientId,
    carbSensitivity,
    targetGlucoseMin,
    targetGlucoseMax,
    maxGlucoseThreshold,
    currentGlucose,
    lastGlucoseReadingTime,
    isRecentReading,
    diabetesType,
    activityLevel,
    createdAt,
    notes,
  ];

  @override
  String toString() {
    return 'PatientGlucoseProfile('
        'sensitivity: $carbSensitivity, '
        'current: $currentGlucose, '
        'target: $targetGlucoseMin-$targetGlucoseMax)';
  }
}
