class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? biografia;
  final String? foto;
  final String fechaRegistro;
  final int tipoUsuario;
  final bool activo;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.biografia,
    this.foto,
    this.fechaRegistro = '',
    this.tipoUsuario = 2,
    this.activo = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id_usr'].toString()),
      nombre: json['nom_usr']?.toString() ?? '',
      correo: json['mail']?.toString() ?? '',
      biografia: json['biografia']?.toString(),
      foto: json['foto']?.toString(),
      fechaRegistro: json['fecha_reg']?.toString() ?? '',
      tipoUsuario: int.tryParse('${json['tip_usu']}') ?? 2,
      activo: json['activo'] == null ? true : json['activo'] == true,
    );
  }
}
