import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'api_config.dart';

// Funciones exclusivas del administrador (tip_usu == 1).
class AdminService {
  Map<String, String> _cabeceras(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<UserModel>> listarUsuarios({
    required String token,
    String busqueda = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/usuarios').replace(
      queryParameters: busqueda.trim().isEmpty ? null : {'q': busqueda.trim()},
    );

    final respuesta = await http
        .get(uri, headers: _cabeceras(token))
        .timeout(const Duration(seconds: 10));

    final dynamic datos = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode != 200 || datos is! List) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo consultar los usuarios'),
      );
    }

    return datos
        .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> cambiarEstado({
    required String token,
    required int idUsuario,
    required bool activo,
  }) async {
    final respuesta = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/admin/usuarios/$idUsuario/estado'),
          headers: _cabeceras(token),
          body: jsonEncode({'activo': activo}),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo cambiar el estado'),
      );
    }
  }

  Future<void> cambiarRol({
    required String token,
    required int idUsuario,
    required int tipo,
  }) async {
    final respuesta = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/admin/usuarios/$idUsuario/rol'),
          headers: _cabeceras(token),
          body: jsonEncode({'tip_usu': tipo}),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo cambiar el rol'),
      );
    }
  }

  Future<void> crearAdministrador({
    required String token,
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/admin/administradores'),
          headers: _cabeceras(token),
          body: jsonEncode({
            'nom_usr': nombre.trim(),
            'mail': correo.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo crear el administrador'),
      );
    }
  }
}
