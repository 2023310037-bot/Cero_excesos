import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comentario_model.dart';
import '../models/reaccion_model.dart';
import 'api_config.dart';

class ComentarioService {
  // RF006: comentarios de una publicación. Si se manda el token, el
  // servidor marca cuáles reacciones son del usuario.

  Future<List<ComentarioModel>> obtenerComentariosPorBlog(
    int blogId, {
    String token = '',
  }) async {
    final respuesta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/blog/$blogId/comentarios'),
      headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(
          respuesta,
          'Error al consultar comentarios de la publicación',
        ),
      );
    }

    final List<dynamic> datos = ApiConfig.decodificar(respuesta);

    return datos
        .map(
          (json) => ComentarioModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // Solo usuarios con sesión pueden comentar (el autor sale del token).

  Future<void> agregarComentario({
    required int blogId,
    required String comentario,
    required String token,
  }) async {
    final respuesta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/comentarios'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'comentario': comentario.trim(),
        'blog_id': blogId,
      }),
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo registrar el comentario'),
      );
    }
  }

  // Reaccionar con un emoji. Si ya habías reaccionado con ese emoji,
  // la reacción se quita. Regresa las reacciones actualizadas.

  Future<List<ReaccionModel>> reaccionar({
    required int comentarioId,
    required String tipo,
    required String token,
  }) async {
    final respuesta = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/comentarios/$comentarioId/reaccion'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'tipo': tipo}),
    ).timeout(const Duration(seconds: 10));

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is List) {
      return resultado
          .map((r) => ReaccionModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo registrar la reacción'),
    );
  }

  // Elimina un comentario (el autor o un administrador).

  Future<void> eliminarComentario({
    required int comentarioId,
    required String token,
  }) async {
    final respuesta = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/comentarios/$comentarioId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo eliminar el comentario'),
      );
    }
  }
}
