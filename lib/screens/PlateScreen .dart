import 'package:flutter/material.dart';

class PlateScreen extends StatefulWidget {
  const PlateScreen({super.key});

  @override
  State<PlateScreen> createState() => _PlateScreenState();
}

class _PlateScreenState extends State<PlateScreen> {
  final _foodController = TextEditingController();
  final _quantityController = TextEditingController();

  // List to store all items in the plate
  final List<Map<String, dynamic>> plateItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Build Your Plate")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _foodController,
              decoration: const InputDecoration(
                  labelText: "Food Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                  labelText: "Quantity (grams)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_foodController.text.isNotEmpty &&
                    _quantityController.text.isNotEmpty) {
                  setState(() {
                    plateItems.add({
                      "food": _foodController.text,
                      "quantity": double.parse(_quantityController.text)
                    });
                    _foodController.clear();
                    _quantityController.clear();
                  });
                }
              },
              child: const Text("Add to Plate"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: plateItems.length,
                itemBuilder: (context, index) {
                  final item = plateItems[index];
                  return ListTile(
                    title: Text("${item['food']}"),
                    subtitle: Text("${item['quantity']} g"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          plateItems.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: plateItems.isEmpty
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/nutritionPlate',
                          arguments: plateItems);
                    },
              child: const Text("Calculate Nutrition for Plate"),
            )
          ],
        ),
      ),
    );
  }
}
