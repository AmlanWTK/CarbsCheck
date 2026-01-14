import 'package:carbcheck/app_colors.dart';
import 'package:carbcheck/services/food_serving_standards.dart';
import 'package:flutter/material.dart';


/// 🔍 Food Search Autocomplete Widget
/// Uses LOCAL JSON database for instant suggestions
/// No network calls - blazing fast!
class FoodSearchAutocomplete extends StatefulWidget {
  final Function(String foodName) onFoodSelected;
  final List<String> excludeFoods; // Already added foods

  const FoodSearchAutocomplete({
    Key? key,
    required this.onFoodSelected,
    this.excludeFoods = const [],
  }) : super(key: key);

  @override
  State<FoodSearchAutocomplete> createState() => _FoodSearchAutocompleteState();
}

class _FoodSearchAutocompleteState extends State<FoodSearchAutocomplete> {
  late TextEditingController _controller;
  List<FoodItem> _suggestions = [];
  late LocalFoodDatabaseService _foodDatabase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _foodDatabase = LocalFoodDatabaseService();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔍 Update suggestions as user types
  /// Uses local database for instant results
  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search in local database (instant!)
      final allResults = _foodDatabase.searchFoods(query);

      // Filter out already selected foods
      final filteredResults = allResults
          .where((food) => !widget.excludeFoods.contains(food.description))
          .take(10) // Show top 10 suggestions
          .toList();

      setState(() {
        _suggestions = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error searching foods: $e');
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  /// Clear search and suggestions
  void _clearSearch() {
    _controller.clear();
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 🔍 Search Field
    TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search foods (e.g., "apple", "rice")...',
        hintStyle: TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.primary,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: _clearSearch,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18, // ⬆ taller field
        ),
      ),
      style: TextStyle(
        fontSize: 16, // ⬆ input text size
        color: AppColors.textPrimary,
      ),
      onChanged: _updateSuggestions,
    ),

    const SizedBox(height: 8),

    // 💡 Loading Indicator
    if (_isLoading)
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),

    // ✅ Suggestions List
    if (_suggestions.isNotEmpty && !_isLoading)
      Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) {
            final food = _suggestions[index];
            return _buildSuggestionTile(food);
          },
        ),
      )

    // ❌ No Results Message
    else if (_controller.text.isNotEmpty &&
        _suggestions.isEmpty &&
        !_isLoading)
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          border: Border.all(color: AppColors.warning),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No foods found',
                    style: TextStyle(
                      fontSize: 15, // ⬆
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try simpler terms like "apple" or "rice"',
                    style: TextStyle(
                      fontSize: 13, // ⬆
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
  ],
);

  }

  /// Build individual suggestion tile
  Widget _buildSuggestionTile(FoodItem food) {
    final isAlreadySelected =
        widget.excludeFoods.contains(food.description);

    return ListTile(
      enabled: !isAlreadySelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Icon(
        Icons.restaurant_menu,
        color: isAlreadySelected ? Colors.grey : Colors.teal,
        size: 20,
      ),
      title: Text(
        food.description,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isAlreadySelected ? Colors.grey : Colors.black,
          decoration:
              isAlreadySelected ? TextDecoration.lineThrough : null,
        ),
      ),
      // subtitle: Text(
      //   '${food.servingSizeGrams}${food.servingSizeUnit} | ${food.carbohydrates.toStringAsFixed(1)}g carbs',
      //   style: TextStyle(
      //     fontSize: 12,
      //     color: Colors.grey[600],
      //   ),
      // ),
      trailing: isAlreadySelected
          ? Icon(Icons.check_circle, color: Colors.green[600], size: 20)
          : const Icon(Icons.add_circle_outline, color: Colors.teal, size: 20),
      onTap: isAlreadySelected
          ? null
          : () {
              widget.onFoodSelected(food.description);
              _clearSearch();
            },
      hoverColor: Colors.teal.withOpacity(0.1),
    );
  }
}
