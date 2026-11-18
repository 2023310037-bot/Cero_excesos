import 'package:flutter/material.dart';

import '../models/reaccion_model.dart';

// Fila de stickers: al tocar uno se agrega al comentario que se escribe.
class StickerPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const StickerPicker({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ReaccionModel.stickers.map((sticker) {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelected(sticker),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Text(
                sticker,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
