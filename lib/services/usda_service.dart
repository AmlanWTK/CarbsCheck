import 'dart:convert';
import 'package:http/http.dart' as http;

class USDAService {
  final String apiKey = "bRh1MNJXp3tkapV1aNrPpPcVJ4EPB8mohpSO5UBA"; 

 Future<Map<String, dynamic>?> getFoodNutrition(String foodName) async {
  final url = Uri.parse(
      "https://api.nal.usda.gov/fdc/v1/foods/search?query=$foodName&pageSize=1&api_key=$apiKey");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['foods'] != null && data['foods'].length > 0) {
      final nutrients = data['foods'][0]['foodNutrients'];
      double carbs = 0, fiber = 0, calories = 0;

      for (var nutrient in nutrients) {
        // Safely convert to double
        var value = nutrient['value'];
        double val = 0;
        if (value is int) {
          val = value.toDouble();
        } else if (value is double) {
          val = value;
        }

        if (nutrient['nutrientName'] == "Carbohydrate, by difference") {
          carbs = val;
        } else if (nutrient['nutrientName'] == "Fiber, total dietary") {
          fiber = val;
        } else if (nutrient['nutrientName'] == "Energy") {
          calories = val;
        }
      }

      return {
        'carbs': carbs,
        'fiber': fiber,
        'netCarbs': carbs - fiber,
        'calories': calories
      };
    }
  }
  return null;
}

}
