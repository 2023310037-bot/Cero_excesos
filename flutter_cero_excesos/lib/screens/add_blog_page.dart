import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/categoria_model.dart';
import '../models/post_model.dart';
import '../services/api_config.dart';
import '../services/categoria_service.dart';
import '../services/post_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/category_chip.dart';
import '../widgets/primary_button.dart';

// RF003: crear una entrada nueva o editar una existente.
class AddBlogPage extends StatefulWidget {
  const AddBlogPage({
    super.key,
  });

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController tituloController = TextEditingController();
  final TextEditingController contenidoController = TextEditingController();

  final PostService postService = PostService();
  final CategoriaService categoriaService = CategoriaService();
  final ImagePicker selector = ImagePicker();

  late Future<List<CategoriaModel>> categoriasFuture;

  Map<String, dynamic> usuarioActual = {};
  PostModel? postEditar;

  bool argumentoLeido = false;
  bool guardando = false;

  int? categoriaSeleccionada;
  XFile? imagenSeleccionada;
  Uint8List? imagenBytes;

  bool get editando => postEditar != null;

  String get token => usuarioActual['access_token']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    categoriasFuture = categoriaService.obtenerCategorias();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argumentoLeido) return;

    argumentoLeido = true;

    final argumento = ModalRoute.of(context)?.settings.arguments;

    if (argumento is Map) {
      usuarioActual = Map<String, dynamic>.from(argumento);

      // Si viene una publicación, la pantalla funciona en modo edición.
      final dynamic editar = usuarioActual.remove('post_editar');

      if (editar is PostModel) {
        postEditar = editar;
        tituloController.text = editar.titulo;
        contenidoController.text = editar.contenido;
        categoriaSeleccionada = editar.categoriaId;
      }
    }

    // Sin sesión no se puede escribir.
    if (token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      });
    }
  }

  @override
  void dispose() {
    tituloController.dispose();
    contenidoController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> seleccionarImagen(ImageSource origen) async {
    try {
      final XFile? imagen = await selector.pickImage(
        source: origen,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagenSeleccionada = imagen;
        imagenBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje('No se pudo seleccionar la fotografía');
    }
  }

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    // RF005: todo artículo debe tener una categoría.
    if (categoriaSeleccionada == null) {
      mostrarMensaje('Selecciona una categoría');
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      if (editando) {
        await postService.editarPost(
          id: postEditar!.id,
          titulo: tituloController.text,
          contenido: contenidoController.text,
          categoriaId: categoriaSeleccionada!,
          token: token,
          imagen: imagenSeleccionada,
        );
      } else {
        await postService.agregarPost(
          titulo: tituloController.text,
          contenido: contenidoController.text,
          categoriaId: categoriaSeleccionada!,
          token: token,
          imagen: imagenSeleccionada,
        );
      }

      if (!mounted) return;

      mostrarMensaje(
        editando ? 'Cambios guardados' : 'Entrada publicada',
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/blog',
        (route) => false,
        arguments: usuarioActual,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  Widget vistaPreviaImagen() {
    if (imagenBytes != null) {
      return Image.memory(
        imagenBytes!,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final actual = postEditar?.imagen;

    if (actual != null && actual.trim().isNotEmpty) {
      return Image.network(
        ApiConfig.urlImagen(actual.trim()),
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(height: 190);
        },
      );
    }

    return Container(
      height: 130,
      width: double.infinity,
      color: const Color(0xFFE4EDDA),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 50,
          color: AppColores.verdeMedio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar entrada' : 'Escribir entrada'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: tituloController,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              const Text(
                'Categoría',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColores.verde,
                ),
              ),

              const SizedBox(height: 8),

              FutureBuilder<List<CategoriaModel>>(
                future: categoriasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'No se pudieron cargar las categorías.',
                      style: TextStyle(color: AppColores.error),
                    );
                  }

                  final categorias = snapshot.data ?? [];

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categorias.map((categoria) {
                      return CategoryChip(
                        text: categoria.nombre,
                        selected: categoriaSeleccionada == categoria.id,
                        onTap: () {
                          setState(() {
                            categoriaSeleccionada = categoria.id;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: contenidoController,
                minLines: 8,
                maxLines: 20,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                  helperText: 'Deja una línea en blanco para separar párrafos.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El contenido es obligatorio';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              const Text(
                'Fotografía (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColores.verde,
                ),
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: vistaPreviaImagen(),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => seleccionarImagen(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Elegir de la galería'),
                ),
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                text: guardando
                    ? 'GUARDANDO...'
                    : (editando ? 'GUARDAR CAMBIOS' : 'PUBLICAR'),
                onPressed: guardando ? null : guardar,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
