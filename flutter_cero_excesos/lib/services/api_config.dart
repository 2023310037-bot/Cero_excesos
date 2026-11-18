import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Datos y funciones que usan todos los servicios.
class ApiConfig {
  // Dirección del servidor FastAPI. CÁMBIALA SOLO AQUÍ:
  //  - Celular físico (misma red WiFi): http://IP_DE_TU_PC:8000
  //  - Emulador de Android:             http://10.0.2.2:8000
  //  - Chrome / Windows:                http://127.0.0.1:8000
static const String baseUrl = 'http://127.0.0.1:8000';

  // Convierte /uploads/foto.png en una dirección completa.
  static String urlImagen(String ruta) {
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      return ruta;
    }

    return '$baseUrl${ruta.startsWith('/') ? ruta : '/$ruta'}';
  }

  // Lee el JSON de la respuesta con UTF-8 (para que se vean bien las tildes).
  static dynamic decodificar(http.Response respuesta) {
    if (respuesta.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(respuesta.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  // Obtiene el mensaje de error que mandó el servidor (campo "detail").
  static String detalle(http.Response respuesta, String porDefecto) {
    final dynamic resultado = decodificar(respuesta);

    if (resultado is Map && resultado['detail'] != null) {
      return resultado['detail'].toString();
    }

    return '$porDefecto (HTTP ${respuesta.statusCode})';
  }

  // Convierte cualquier error en un texto entendible para el usuario.
  static String mensajeError(Object error) {
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder.';
    }

    if (error is http.ClientException) {
      return 'No hay conexión con el servidor. Revisa tu red y la '
          'dirección en api_config.dart.';
    }

    final texto = error.toString();

    if (texto.startsWith('Exception: ')) {
      return texto.substring('Exception: '.length);
    }

    return 'Ocurrió un error inesperado.';
  }

  // 2026-10-31T10:30:00  ->  31/10/2026
  static String fechaCorta(String iso) {
    final fecha = DateTime.tryParse(iso);

    if (fecha == null) return '';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  // Garantiza que el nombre del archivo tenga una extensión válida.
  static String nombreArchivo(XFile imagen) {
    final nombre = imagen.name.toLowerCase();

    const permitidas = ['.jpg', '.jpeg', '.png', '.webp'];

    if (permitidas.any((extension) => nombre.endsWith(extension))) {
      return imagen.name;
    }

    final tipo = imagen.mimeType ?? '';

    if (tipo == 'image/png') return '${imagen.name}.png';
    if (tipo == 'image/webp') return '${imagen.name}.webp';

    return '${imagen.name}.jpg';
  }

  // Envía un formulario con campos de texto y, si hay, una fotografía.
  static Future<http.Response> enviarFormulario({
    required String metodo,
    required String ruta,
    required String token,
    required Map<String, String> campos,
    XFile? imagen,
  }) async {
    final solicitud = http.MultipartRequest(
      metodo,
      Uri.parse('$baseUrl$ruta'),
    );

    solicitud.headers['Accept'] = 'application/json';
    solicitud.headers['Authorization'] = 'Bearer $token';
    solicitud.fields.addAll(campos);

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();

      solicitud.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: nombreArchivo(imagen),
        ),
      );
    }

    final enviada = await solicitud.send().timeout(
      const Duration(seconds: 30),
    );

    return http.Response.fromStream(enviada);
  }
}
