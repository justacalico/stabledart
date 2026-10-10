import 'package:flutter/material.dart';

class NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int? min;
  final int? max;

  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: min == null || value > min!
                  ? () => onChanged(value - 1)
                  : null,
              icon: const Icon(Icons.remove, size: 16),
            ),
            SizedBox(
              width: 64,
              child: TextFormField(
                key: ValueKey(value),
                initialValue: '$value',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed == null) return;
                  if (min != null && parsed < min!) return;
                  if (max != null && parsed > max!) return;
                  onChanged(parsed);
                },
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: max == null || value < max!
                  ? () => onChanged(value + 1)
                  : null,
              icon: const Icon(Icons.add, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}
