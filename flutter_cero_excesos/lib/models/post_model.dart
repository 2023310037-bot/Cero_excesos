class PostModel {
  final int id;
  final String titulo;
  final String contenido;
  final String? imagen;
  final String fecha;
  final int usuarioId;
  final String autor;
  final int categoriaId;
  final String categoria;
  final double promedio;
  final int totalValoraciones;

  PostModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.imagen,
    required this.fecha,
    required this.usuarioId,
    required this.autor,
    required this.categoriaId,
    required this.categoria,
    this.promedio = 0.0,
    this.totalValoraciones = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: int.parse(json['id_blog'].toString()),
      titulo: json['titulo']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      imagen: json['img']?.toString(),
      fecha: json['fecha']?.toString() ?? '',
      usuarioId: int.parse(json['usr_id'].toString()),
      autor: json['autor']?.toString() ?? 'Usuario',
      categoriaId: int.parse(json['cat_id'].toString()),
      categoria: json['nom_cat']?.toString() ?? '',
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0.0,
      totalValoraciones: int.tryParse('${json['total_valoraciones']}') ?? 0,
    );
  }
}
