import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/valoracion_model.dart';
import 'api_config.dart';

class ValoracionService {
  // Promedio de estrellas de una entrada (y la valoración del usuario,
  // si manda su token).

  Future<ValoracionModel> obtenerValoracion(
    int blogId, {
    String token = '',
  }) async {
    final respuesta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/blog/$blogId/valoracion'),
      headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return ValoracionModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo consultar la valoración'),
    );
  }

  // Califica una entrada de 1 a 5 estrellas.

  Future<ValoracionModel> valorar({
    required int blogId,
    required int puntos,
    required String token,
  }) async {
    final respuesta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/blog/$blogId/valoracion'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'puntos': puntos}),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return ValoracionModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo guardar la valoración'),
    );
  }
}
