// Reacciones a comentarios y stickers (módulo de comentarios interactivos).
class ReaccionModel {
  final String tipo;
  final int total;
  final bool mia;

  ReaccionModel({
    required this.tipo,
    required this.total,
    required this.mia,
  });

  factory ReaccionModel.fromJson(Map<String, dynamic> json) {
    return ReaccionModel(
      tipo: json['tipo']?.toString() ?? '',
      total: int.tryParse('${json['total']}') ?? 0,
      mia: json['mia'] == true,
    );
  }

  String get emoji => emojis[tipo] ?? '👍';

  // El servidor guarda el nombre de la reacción; aquí se convierte en emoji.
  static const Map<String, String> emojis = {
    'me_gusta': '👍',
    'me_encanta': '❤️',
    'risa': '😂',
    'asombro': '😮',
    'tristeza': '😢',
    'fuego': '🔥',
  };

  // Stickers que se pueden insertar al escribir un comentario.
  static const List<String> stickers = [
    '🎉',
    '💸',
    '💪',
    '🔥',
    '😂',
    '👏',
    '❤️',
    '🥳',
    '🤑',
    '🥗',
  ];

  // Un comentario hecho solo de stickers se muestra en grande.
  static bool esSoloStickers(String texto) {
    var resto = texto.trim();

    if (resto.isEmpty) return false;

    for (final sticker in stickers) {
      resto = resto.replaceAll(sticker, '');
    }

    return resto.trim().isEmpty;
  }
}
