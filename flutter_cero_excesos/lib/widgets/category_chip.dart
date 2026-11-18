import 'package:flutter/material.dart';

import 'app_colores.dart';

class CategoryChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColores.verde : Colors.transparent,
          border: Border.all(
            color: selected ? AppColores.verde : AppColores.linea,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : AppColores.textoSuave,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
