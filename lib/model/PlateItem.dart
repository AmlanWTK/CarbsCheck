

import 'package:equatable/equatable.dart';

class PlateItem with EquatableMixin {
  /// Name of the food (e.g., "rice", "chicken", "apple")
  final String foodName;
  final String selectedUnit;

  final int quantity;
  final String? usdaFdcId;
  final double portionInGrams;
  final double standardServingGrams;
  final String servingSizeDesc;
  final DateTime? addedAt;

  PlateItem({
    required this.foodName,
    required this.selectedUnit,
    required this.quantity,
    required this.portionInGrams,
    required this.standardServingGrams,
    required this.servingSizeDesc,
    this.usdaFdcId,
    this.addedAt,
  });

  PlateItem copyWith({
    String? foodName,
    String? selectedUnit,
    int? quantity,
    String? usdaFdcId,
    double? portionInGrams,
    double? standardServingGrams,
    String? servingSizeDesc,
    DateTime? addedAt,
  }) {
    return PlateItem(
      foodName: foodName ?? this.foodName,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      quantity: quantity ?? this.quantity,
      usdaFdcId: usdaFdcId ?? this.usdaFdcId,
      portionInGrams: portionInGrams ?? this.portionInGrams,
      standardServingGrams: standardServingGrams ?? this.standardServingGrams,
      servingSizeDesc: servingSizeDesc ?? this.servingSizeDesc,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'foodName': foodName,
    'selectedUnit': selectedUnit,
    'quantity': quantity,
    'usdaFdcId': usdaFdcId,
    'portionInGrams': portionInGrams,
    'standardServingGrams': standardServingGrams,
    'servingSizeDesc': servingSizeDesc,
    'addedAt': addedAt?.toIso8601String(),
  };


  factory PlateItem.fromJson(Map<String, dynamic> json) {
    return PlateItem(
      foodName: json['foodName'] as String,
      selectedUnit: json['selectedUnit'] as String,
      quantity: json['quantity'] as int,
      usdaFdcId: json['usdaFdcId'] as String?,
      portionInGrams: (json['portionInGrams'] as num).toDouble(),
      standardServingGrams: (json['standardServingGrams'] as num).toDouble(),
      servingSizeDesc: json['servingSizeDesc'] as String,
      addedAt: json['addedAt'] != null 
          ? DateTime.parse(json['addedAt'] as String)
          : null,
    );
  }

  double getPortionMultiplier() {
    switch (selectedUnit.toLowerCase()) {
      case 'small':
        return 0.67;
      case 'large':
        return 1.5;
      case 'medium':
      default:
        return 1.0;
    }
  }

  String getPortionDescription() {
    return '$quantity × $selectedUnit ($portionInGrams g $foodName)';
  }


  String getShortDescription() {
    final quantityStr = quantity > 1 ? '$quantity ' : '';
    return '$quantityStr$selectedUnit ${foodName.toLowerCase()} ($portionInGrams g)';
  }

  bool isValid() {
    final validUnits = ['Small', 'Medium', 'Large'];
    return foodName.isNotEmpty &&
        quantity > 0 &&
        portionInGrams > 0 &&
        validUnits.contains(selectedUnit);
  }

  @override
  List<Object?> get props => [
    foodName,
    selectedUnit,
    quantity,
    usdaFdcId,
    portionInGrams,
    standardServingGrams,
    servingSizeDesc,
    addedAt,
  ];

  @override
  String toString() {
    return 'PlateItem('
        'foodName: $foodName, '
        'selectedUnit: $selectedUnit, '
        'quantity: $quantity, '
        'usdaFdcId: $usdaFdcId, '
        'portionInGrams: $portionInGrams, '
        'standardServingGrams: $standardServingGrams, '
        'servingSizeDesc: $servingSizeDesc)';
  }
}
