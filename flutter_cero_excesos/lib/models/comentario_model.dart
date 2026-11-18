import 'reaccion_model.dart';

class ComentarioModel {
  final int id;
  final String comentario;
  final String fecha;
  final int estatus;
  final int usuarioId;
  final int blogId;
  final String autor;

  // No es final: se actualiza cuando el usuario reacciona.
  List<ReaccionModel> reacciones;

  ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.estatus,
    required this.usuarioId,
    required this.blogId,
    required this.autor,
    this.reacciones = const [],
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final lista = (json['reacciones'] as List<dynamic>?) ?? [];

    return ComentarioModel(
      id: int.parse(json['id_com'].toString()),
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      estatus: int.parse(json['estatus'].toString()),
      usuarioId: int.parse(json['usr_id'].toString()),
      blogId: int.parse(json['blog_id'].toString()),
      autor: json['autor']?.toString() ?? 'Usuario',
      reacciones: lista
          .map((r) => ReaccionModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
