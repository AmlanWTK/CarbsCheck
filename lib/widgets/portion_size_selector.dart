import 'package:flutter/material.dart';

class PortionSizeSelector extends StatefulWidget {
  final String selectedPortion;
  final List<String> portions;
  final Function(String) onPortionChanged;

  const PortionSizeSelector({
    Key? key,
    required this.selectedPortion,
    required this.portions,
    required this.onPortionChanged,
  }) : super(key: key);

  @override
  State<PortionSizeSelector> createState() => _PortionSizeSelectorState();
}

class _PortionSizeSelectorState extends State<PortionSizeSelector> {
  late String _selectedPortion;

  @override
  void initState() {
    super.initState();
    _selectedPortion = widget.selectedPortion;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portion Size',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: widget.portions
              .map((portion) => ButtonSegment(
                    label: Text(portion),
                    value: portion,
                  ))
              .toList(),
          selected: {_selectedPortion},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() => _selectedPortion = newSelection.first);
            widget.onPortionChanged(newSelection.first);
          },
        ),
      ],
    );
  }
}
