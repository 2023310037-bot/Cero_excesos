import 'package:flutter/material.dart';

import 'app_colores.dart';

// Estrellas de 1 a 5. Sin onSelected solo muestra el valor (promedio);
// con onSelected el usuario puede tocar una estrella para calificar.
class StarRating extends StatelessWidget {
  final double valor;
  final double size;
  final ValueChanged<int>? onSelected;

  const StarRating({
    super.key,
    required this.valor,
    this.size = 24,
    this.onSelected,
  });

  IconData icono(int numero) {
    if (valor >= numero) return Icons.star;
    if (valor >= numero - 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final numero = indice + 1;

        final estrella = Icon(
          icono(numero),
          color: AppColores.estrella,
          size: size,
        );

        if (onSelected == null) return estrella;

        return InkWell(
          onTap: () => onSelected!(numero),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: estrella,
          ),
        );
      }),
    );
  }
}
