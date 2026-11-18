import 'package:http/http.dart' as http;

import '../models/categoria_model.dart';
import 'api_config.dart';

class CategoriaService {
  // Categorías disponibles.

  Future<List<CategoriaModel>> obtenerCategorias() async {
    final respuesta = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/categorias'),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        ApiConfig.detalle(respuesta, 'Error al consultar categorías'),
      );
    }

    final List<dynamic> datos = ApiConfig.decodificar(respuesta);

    return datos
        .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
