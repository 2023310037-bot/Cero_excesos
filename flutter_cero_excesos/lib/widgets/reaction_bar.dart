import 'package:flutter/material.dart';

import '../models/reaccion_model.dart';
import 'app_colores.dart';

// Reacciones de un comentario: muestra las que ya tiene (con su contador)
// y un botón para agregar otra.
class ReactionBar extends StatelessWidget {
  final List<ReaccionModel> reacciones;
  final bool habilitado;
  final ValueChanged<String> onReaccionar;

  const ReactionBar({
    super.key,
    required this.reacciones,
    required this.habilitado,
    required this.onReaccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final reaccion in reacciones)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: habilitado ? () => onReaccionar(reaccion.tipo) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: reaccion.mia
                    ? AppColores.lima
                    : const Color(0xFFE4EDDA),
                borderRadius: BorderRadius.circular(16),
                border: reaccion.mia
                    ? Border.all(color: AppColores.verde, width: 1.5)
                    : null,
              ),
              child: Text(
                '${reaccion.emoji} ${reaccion.total}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColores.verde,
                ),
              ),
            ),
          ),

        PopupMenuButton<String>(
          enabled: habilitado,
          tooltip: habilitado ? 'Reaccionar' : 'Inicia sesión para reaccionar',
          icon: const Icon(
            Icons.add_reaction_outlined,
            size: 22,
            color: AppColores.textoSuave,
          ),
          padding: EdgeInsets.zero,
          onSelected: onReaccionar,
          itemBuilder: (context) {
            return ReaccionModel.emojis.entries.map((entrada) {
              return PopupMenuItem<String>(
                value: entrada.key,
                child: Text(
                  entrada.value,
                  style: const TextStyle(fontSize: 26),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
