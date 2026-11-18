class CategoriaModel {
  final int id;
  final String nombre;

  CategoriaModel({
    required this.id,
    required this.nombre,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: int.parse(json['id_cat'].toString()),
      nombre: json['nom_cat']?.toString() ?? '',
    );
  }
}
