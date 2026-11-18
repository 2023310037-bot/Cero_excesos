import 'package:flutter/material.dart';

import '../models/categoria_model.dart';
import '../models/post_model.dart';
import '../services/categoria_service.dart';
import '../services/post_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/category_chip.dart';
import '../widgets/post_card.dart';
import '../widgets/user_drawer.dart';
import 'post_detail_page.dart';

// RF004 (consultar publicaciones) y RF005 (filtrar por categoría).
class BlogPage extends StatefulWidget {
  const BlogPage({
    super.key,
  });

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService postService = PostService();
  final CategoriaService categoriaService = CategoriaService();
  final TextEditingController busquedaController = TextEditingController();

  late Future<List<PostModel>> postsFuture;
  late Future<List<CategoriaModel>> categoriasFuture;

  // Sesión: vacía cuando el usuario entra sin iniciar sesión.
  Map<String, dynamic> usuarioActual = {};

  bool argumentoLeido = false;
  int? categoriaSeleccionada;
  bool soloMisEntradas = false;

  bool get haySesion =>
      (usuarioActual['access_token']?.toString() ?? '').isNotEmpty;

  int? get idUsuario => int.tryParse('${usuarioActual['id_usr']}');

  String get nombreUsuario =>
      usuarioActual['nom_usr']?.toString() ?? 'visitante';

  @override
  void initState() {
    super.initState();
    categoriasFuture = categoriaService.obtenerCategorias();
    postsFuture = consultarPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!argumentoLeido) {
      final argumento = ModalRoute.of(context)?.settings.arguments;

      if (argumento is Map) {
        usuarioActual = Map<String, dynamic>.from(argumento);
      }

      argumentoLeido = true;
    }
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  Future<List<PostModel>> consultarPosts() {
    return postService.obtenerPosts(
      categoriaId: categoriaSeleccionada,
      usuarioId: soloMisEntradas ? idUsuario : null,
      busqueda: busquedaController.text,
    );
  }

  void recargarPosts() {
    setState(() {
      postsFuture = consultarPosts();
    });
  }

  void seleccionarCategoria(int? id) {
    categoriaSeleccionada = id;

    // "TODAS" quita también el filtro de mis entradas.
    if (id == null) soloMisEntradas = false;

    recargarPosts();
  }

  void alternarMisEntradas() {
    soloMisEntradas = !soloMisEntradas;
    recargarPosts();
  }

  void escribirEntrada() {
    if (!haySesion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para escribir una entrada'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/add-blog',
      arguments: usuarioActual,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cero Excesos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: recargarPosts,
          ),
        ],
      ),

      drawer: UserDrawer(
        usuario: usuarioActual,
        rutaActual: '/blog',
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Escribir'),
        onPressed: escribirEntrada,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            haySesion ? 'Hola, $nombreUsuario' : 'Vive bien con lo justo',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColores.verde,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Dinero, hábitos y entrenamiento para la vida universitaria',
            style: TextStyle(
              fontSize: 16,
              color: AppColores.textoSuave,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: busquedaController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar entradas',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onSubmitted: (_) => recargarPosts(),
          ),

          const SizedBox(height: 12),

          // Categorías (RF005)
          FutureBuilder<List<CategoriaModel>>(
            future: categoriasFuture,
            builder: (context, snapshot) {
              final categorias = snapshot.data ?? [];

              return SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      text: 'TODAS',
                      selected: categoriaSeleccionada == null &&
                          !soloMisEntradas,
                      onTap: () => seleccionarCategoria(null),
                    ),

                    // Entradas propias (se ven junto con las de los demás
                    // cuando está desactivado).
                    if (haySesion) ...[
                      const SizedBox(width: 10),

                      CategoryChip(
                        text: 'MIS ENTRADAS',
                        selected: soloMisEntradas,
                        onTap: alternarMisEntradas,
                      ),
                    ],

                    for (final categoria in categorias) ...[
                      const SizedBox(width: 10),

                      CategoryChip(
                        text: categoria.nombre,
                        selected: categoriaSeleccionada == categoria.id,
                        onTap: () => seleccionarCategoria(categoria.id),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          FutureBuilder<List<PostModel>>(
            future: postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: AppColores.error,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'No se pudieron cargar las publicaciones.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: recargarPosts,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final List<PostModel> posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      soloMisEntradas
                          ? 'Aún no has escrito entradas.'
                          : 'Todavía no hay publicaciones aquí.',
                    ),
                  ),
                );
              }

              return Column(
                children: posts.map((post) {
                  return PostCard(
                    post: post,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailPage(
                            post: post,
                            usuario: usuarioActual,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
