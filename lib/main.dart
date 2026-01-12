import 'package:carbcheck/screens/PlateScreen%20.dart';
import 'package:carbcheck/screens/nutrition_screen.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp - FoodImpact Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        // Main screen for adding multiple foods
        '/': (context) => const PlateScreen(),

        // Nutrition screen for full plate
        '/nutritionPlate': (context) => NutritionPlateScreen(
              plateItems: ModalRoute.of(context)!.settings.arguments
                  as List<Map<String, dynamic>>,
            ),
      },
    );
  }
}
