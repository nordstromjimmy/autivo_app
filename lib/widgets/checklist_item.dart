import 'package:flutter/material.dart';

class ChecklistItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const ChecklistItem({
    super.key,
    required this.title,
    required this.description,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              decoration: isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.green,
      ),
    );
  }
}
