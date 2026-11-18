import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthService {
  // VALIDAR INICIO DE SESIÓN

  String? validarLogin({
    required String correo,
    required String password,
  }) {
    if (correo.trim().isEmpty || password.isEmpty) {
      return 'Por favor ingrese todos los campos';
    }

    return null;
  }

  // VALIDAR REGISTRO

  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarPassword,
  }) {
    if (nombre.trim().isEmpty ||
        correo.trim().isEmpty ||
        password.isEmpty ||
        confirmarPassword.isEmpty) {
      return 'Por favor ingrese todos los campos';
    }

    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (!correo.contains('@') || !correo.contains('.')) {
      return 'Por favor ingrese un correo válido';
    }

    if (password != confirmarPassword) {
      return 'Las contraseñas no coinciden';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    return null;
  }

  // AUTENTICAR USUARIO

  Future<Map<String, dynamic>> autenticar({
    required String correo,
    required String password,
  }) async {
    final respuesta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'mail': correo.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 &&
        resultado is Map<String, dynamic>) {
      return resultado;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'Error al iniciar sesión'),
    );
  }

  // REGISTRAR USUARIO

  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final respuesta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nom_usr': nombre.trim(),
        'mail': correo.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return resultado;
    }

    if (respuesta.statusCode == 409) {
      throw Exception('El correo ya está registrado');
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'Error al registrar usuario'),
    );
  }
}
