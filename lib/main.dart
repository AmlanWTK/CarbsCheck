import 'package:flutter/material.dart';
import 'package:carbcheck/screens/meal_estimation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarbCheck - Meal Estimation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MealEstimationApp(),
    );
  }
}

class MealEstimationApp extends StatefulWidget {
  const MealEstimationApp({super.key});

  @override
  State<MealEstimationApp> createState() => _MealEstimationAppState();
}

class _MealEstimationAppState extends State<MealEstimationApp> {
  @override
  Widget build(BuildContext context) {
    return MealEstimationScreen(
      patientProfile: null,
      onMealEstimated: (estimate) {
        _showMealSaved(estimate);
      },
    );
  }

  void _showMealSaved(dynamic estimate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meal estimate saved: ${estimate.mealType}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
