import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'api_config.dart';

class UserService {
  // Consultar el perfil de la sesión activa.

  Future<UserModel> obtenerMiPerfil(String token) async {
    final respuesta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/perfil/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return UserModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo consultar el perfil'),
    );
  }

  // Actualizar nombre, biografía y fotografía.

  Future<UserModel> actualizarMiPerfil({
    required String token,
    required String nombre,
    required String biografia,
    XFile? imagen,
  }) async {
    final respuesta = await ApiConfig.enviarFormulario(
      metodo: 'PUT',
      ruta: '/perfil/me',
      token: token,
      campos: {
        'nom_usr': nombre.trim(),
        'biografia': biografia.trim(),
      },
      imagen: imagen,
    );

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return UserModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo actualizar el perfil'),
    );
  }

  // Cambiar el correo (pide la contraseña actual).

  Future<UserModel> cambiarCorreo({
    required String token,
    required String nuevoCorreo,
    required String passwordActual,
  }) async {
    final respuesta = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/perfil/me/correo'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mail': nuevoCorreo.trim().toLowerCase(),
        'password_actual': passwordActual,
      }),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return UserModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo cambiar el correo'),
    );
  }

  // Cambiar la contraseña (pide la contraseña actual).

  Future<void> cambiarPassword({
    required String token,
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final respuesta = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/perfil/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      }),
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo cambiar la contraseña'),
      );
    }
  }
}
