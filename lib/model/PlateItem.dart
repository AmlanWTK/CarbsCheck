class PlateItem {
  final String foodName;
  final String selectedUnit;
  final int quantity;

  PlateItem({
    required this.foodName,
    required this.selectedUnit,
    required this.quantity,
  });

  PlateItem copyWith({
    String? foodName,
    String? selectedUnit,
    int? quantity,
  }) {
    return PlateItem(
      foodName: foodName ?? this.foodName,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      quantity: quantity ?? this.quantity,
    );
  }
}
