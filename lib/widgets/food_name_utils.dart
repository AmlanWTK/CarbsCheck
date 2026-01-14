import 'unit_to_gram.dart';

/// Normalize USDA food names for matching
String normalizeFoodName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .trim();
}

/// Maps USDA names → local unit keys
const Map<String, String> foodAliasMap = {
  'white rice': 'rice (cooked)',
  'cooked white rice': 'rice (cooked)',
  'boiled rice': 'rice (cooked)',
};

/// Resolve unit map safely with fallback
Map<String, double> resolveUnits(String foodName) {
  final normalized = normalizeFoodName(foodName);
  final resolvedKey = foodAliasMap[normalized] ?? normalized;

  return unitToGram[resolvedKey] ?? {'100 g': 100};
}
