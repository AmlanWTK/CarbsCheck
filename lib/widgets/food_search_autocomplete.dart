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
            prefixIcon: const Icon(Icons.search, color: Colors.teal),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          onChanged: _updateSuggestions,
        ),
        const SizedBox(height: 8),

        // 💡 Loading Indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.teal[600]),
              ),
            ),
          ),

        // ✅ Suggestions List
        if (_suggestions.isNotEmpty && !_isLoading)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
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
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No foods found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try simpler terms like "apple" or "rice"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
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
