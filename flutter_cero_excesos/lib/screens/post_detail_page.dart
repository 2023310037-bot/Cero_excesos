import 'package:flutter/material.dart';

import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../models/reaccion_model.dart';
import '../models/valoracion_model.dart';
import '../services/api_config.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../services/valoracion_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/star_rating.dart';
import '../widgets/sticker_picker.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final Map<String, dynamic> usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.usuario,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ComentarioService comentarioService = ComentarioService();
  final ValoracionService valoracionService = ValoracionService();
  final PostService postService = PostService();
  final TextEditingController comentarioController = TextEditingController();

  late Future<List<ComentarioModel>> comentariosFuture;
  late Future<ValoracionModel> valoracionFuture;

  bool enviando = false;

  PostModel get post => widget.post;

  String get token => widget.usuario['access_token']?.toString() ?? '';

  bool get haySesion => token.isNotEmpty;

  int get idUsuario => int.tryParse('${widget.usuario['id_usr']}') ?? -1;

  int get tipoUsuario => int.tryParse('${widget.usuario['tip_usu']}') ?? 2;

  // Solo el autor edita; el autor o el administrador pueden eliminar.
  bool get esAutor => haySesion && post.usuarioId == idUsuario;

  bool get puedeEliminar => esAutor || (haySesion && tipoUsuario == 1);

  @override
  void initState() {
    super.initState();
    comentariosFuture = cargarComentarios();
    valoracionFuture = cargarValoracion();
  }

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  Future<List<ComentarioModel>> cargarComentarios() {
    return comentarioService.obtenerComentariosPorBlog(
      post.id,
      token: token,
    );
  }

  Future<ValoracionModel> cargarValoracion() {
    return valoracionService.obtenerValoracion(post.id, token: token);
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void irALogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void editarPost() {
    Navigator.pushNamed(
      context,
      '/add-blog',
      arguments: {
        ...widget.usuario,
        'post_editar': post,
      },
    );
  }

  Future<void> eliminarPost() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar entrada'),
          content: const Text(
            '¿Eliminar esta entrada y sus comentarios? '
            'No se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColores.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await postService.eliminarPost(id: post.id, token: token);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/blog',
        (route) => false,
        arguments: widget.usuario,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  // VALORACIÓN CON ESTRELLAS

  Future<void> valorar(int puntos) async {
    try {
      final resultado = await valoracionService.valorar(
        blogId: post.id,
        puntos: puntos,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        valoracionFuture = Future.value(resultado);
      });

      mostrarMensaje('Valoraste esta entrada con $puntos estrellas');
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  Widget seccionValoracion() {
    return FutureBuilder<ValoracionModel>(
      future: valoracionFuture,
      builder: (context, snapshot) {
        final valoracion = snapshot.data;

        final promedio = valoracion?.promedio ?? 0.0;
        final total = valoracion?.total ?? 0;
        final mia = valoracion?.miPuntuacion;

        Widget accionUsuario;

        if (!haySesion) {
          accionUsuario = TextButton(
            onPressed: irALogin,
            child: const Text('Inicia sesión para valorar'),
          );
        } else if (esAutor) {
          accionUsuario = const Text(
            'No puedes valorar tu propia entrada',
            style: TextStyle(color: AppColores.textoSuave),
          );
        } else {
          accionUsuario = Row(
            children: [
              Text(
                mia == null ? 'Tu valoración:' : 'Tu valoración ($mia):',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(width: 8),

              StarRating(
                valor: (mia ?? 0).toDouble(),
                size: 30,
                onSelected: valorar,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRating(valor: promedio, size: 26),

                const SizedBox(width: 8),

                Text(
                  total == 0
                      ? 'Aún sin valoraciones'
                      : '${promedio.toStringAsFixed(1)} · $total '
                          '${total == 1 ? 'valoración' : 'valoraciones'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSuave,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            accionUsuario,
          ],
        );
      },
    );
  }

  // COMENTARIOS, REACCIONES Y STICKERS

  Future<void> enviarComentario() async {
    final texto = comentarioController.text.trim();

    // No se permiten comentarios vacíos.
    if (texto.isEmpty) {
      mostrarMensaje('No puedes publicar un comentario vacío');
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await comentarioService.agregarComentario(
        blogId: post.id,
        comentario: texto,
        token: token,
      );

      comentarioController.clear();

      if (!mounted) return;

      setState(() {
        comentariosFuture = cargarComentarios();
      });
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  Future<void> reaccionar(ComentarioModel comentario, String tipo) async {
    try {
      final nuevas = await comentarioService.reaccionar(
        comentarioId: comentario.id,
        tipo: tipo,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        comentario.reacciones = nuevas;
      });
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  void agregarSticker(String sticker) {
    final texto = comentarioController.text + sticker;

    comentarioController.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  Widget formularioComentario() {
    if (!haySesion) {
      return TextButton(
        onPressed: irALogin,
        child: const Text('Inicia sesión para comentar y reaccionar'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StickerPicker(onSelected: agregarSticker),

        const SizedBox(height: 6),

        TextField(
          controller: comentarioController,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: 'Escribe un comentario',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: enviando ? null : enviarComentario,
          child: Text(enviando ? 'Enviando...' : 'Comentar'),
        ),
      ],
    );
  }

  Future<void> eliminarComentario(ComentarioModel comentario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Seguro que quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColores.error),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await comentarioService.eliminarComentario(
        comentarioId: comentario.id,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        comentariosFuture = cargarComentarios();
      });

      mostrarMensaje('Comentario eliminado');
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  Widget tarjetaComentario(ComentarioModel comentario) {
    // El administrador puede borrar cualquiera; cada quien, los suyos.
    final puedeEliminar = haySesion &&
        (tipoUsuario == 1 || comentario.usuarioId == idUsuario);

    final esSticker = ReaccionModel.esSoloStickers(comentario.comentario);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD3DCCB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${comentario.autor} · '
                  '${ApiConfig.fechaCorta(comentario.fecha)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColores.verde,
                  ),
                ),
              ),

              if (puedeEliminar)
                IconButton(
                  tooltip: 'Eliminar comentario',
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  color: AppColores.textoSuave,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => eliminarComentario(comentario),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            comentario.comentario,
            style: TextStyle(
              fontSize: esSticker ? 44 : 15,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 6),

          ReactionBar(
            reacciones: comentario.reacciones,
            habilitado: haySesion,
            onReaccionar: (tipo) => reaccionar(comentario, tipo),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagen =
        post.imagen != null && post.imagen!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada'),
        actions: [
          if (esAutor)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: editarPost,
            ),

          if (puedeEliminar)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: eliminarPost,
            ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (tieneImagen)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ApiConfig.urlImagen(post.imagen!.trim()),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  );
                },
              ),
            ),

          if (tieneImagen) const SizedBox(height: 16),

          Text(
            post.categoria,
            style: const TextStyle(
              color: AppColores.verdeMedio,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            post.titulo,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: AppColores.verde,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Por ${post.autor} · ${ApiConfig.fechaCorta(post.fecha)}',
            style: const TextStyle(color: AppColores.textoSuave),
          ),

          const SizedBox(height: 14),

          seccionValoracion(),

          const SizedBox(height: 20),

          Text(
            post.contenido,
            style: const TextStyle(fontSize: 17, height: 1.7),
          ),

          const SizedBox(height: 30),

          const Divider(color: AppColores.verde, thickness: 2),

          // Comentarios (RF006)
          FutureBuilder<List<ComentarioModel>>(
            future: comentariosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No se pudieron cargar los comentarios.'),
                );
              }

              final comentarios = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentarios (${comentarios.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (comentarios.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aún no hay comentarios. Escribe el primero.',
                        style: TextStyle(color: AppColores.textoSuave),
                      ),
                    ),

                  ...comentarios.map(tarjetaComentario),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          formularioComentario(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
