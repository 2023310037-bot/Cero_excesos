import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';
import 'api_config.dart';

class PostService {
  // ==========================================
  // RF003: AGREGAR PUBLICACIÓN (FOTOGRAFÍA OPCIONAL)
  // ==========================================

  Future<PostModel> agregarPost({
    required String titulo,
    required String contenido,
    required int categoriaId,
    required String token,
    XFile? imagen,
  }) async {
    final respuesta = await ApiConfig.enviarFormulario(
      metodo: 'POST',
      ruta: '/blog',
      token: token,
      campos: {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'cat_id': categoriaId.toString(),
      },
      imagen: imagen,
    );

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return PostModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo guardar la publicación'),
    );
  }

  // ==========================================
  // RF003: EDITAR PUBLICACIÓN (SOLO EL AUTOR)
  // ==========================================

  Future<PostModel> editarPost({
    required int id,
    required String titulo,
    required String contenido,
    required int categoriaId,
    required String token,
    XFile? imagen,
  }) async {
    final respuesta = await ApiConfig.enviarFormulario(
      metodo: 'PUT',
      ruta: '/blog/$id',
      token: token,
      campos: {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'cat_id': categoriaId.toString(),
      },
      imagen: imagen,
    );

    final dynamic resultado = ApiConfig.decodificar(respuesta);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return PostModel.fromJson(resultado);
    }

    throw Exception(
      ApiConfig.detalle(respuesta, 'No se pudo actualizar la publicación'),
    );
  }

  // ==========================================
  // RF004 y RF005: CONSULTAR PUBLICACIONES
  // ==========================================

  Future<List<PostModel>> obtenerPosts({
    int? categoriaId,
    int? usuarioId,
    String? busqueda,
  }) async {
    final parametros = <String, String>{
      if (categoriaId != null) 'cat_id': categoriaId.toString(),
      if (usuarioId != null) 'usr_id': usuarioId.toString(),
      if (busqueda != null && busqueda.trim().isNotEmpty)
        'q': busqueda.trim(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/blog').replace(
      queryParameters: parametros.isEmpty ? null : parametros,
    );

    final respuesta = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'Error al consultar publicaciones'),
      );
    }

    final List<dynamic> datos = ApiConfig.decodificar(respuesta);

    return datos
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  // ELIMINAR PUBLICACIÓN (AUTOR O ADMINISTRADOR)
  // ==========================================

  Future<void> eliminarPost({
    required int id,
    required String token,
  }) async {
    final respuesta = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/blog/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'No se pudo eliminar la publicación'),
      );
    }
  }
}
