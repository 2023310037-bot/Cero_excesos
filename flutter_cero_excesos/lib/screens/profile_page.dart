import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/api_config.dart';
import '../services/user_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/dialogo_cambiar_correo.dart';
import '../widgets/dialogo_cambiar_password.dart';
import '../widgets/primary_button.dart';
import '../widgets/user_drawer.dart';

// El usuario consulta y edita solo el perfil de su sesión.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController biografiaController = TextEditingController();

  final UserService userService = UserService();
  final ImagePicker selector = ImagePicker();

  Map<String, dynamic> usuarioActual = {};
  UserModel? perfil;

  bool argumentoLeido = false;
  bool cargando = true;
  bool guardando = false;
  String? errorCarga;

  XFile? imagenNueva;
  Uint8List? imagenBytes;

  String get token => usuarioActual['access_token']?.toString() ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argumentoLeido) return;

    argumentoLeido = true;

    final argumento = ModalRoute.of(context)?.settings.arguments;

    if (argumento is Map) {
      usuarioActual = Map<String, dynamic>.from(argumento);
    }

    if (token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      });
      return;
    }

    cargarPerfil();
  }

  @override
  void dispose() {
    nombreController.dispose();
    biografiaController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> cargarPerfil() async {
    try {
      final resultado = await userService.obtenerMiPerfil(token);

      if (!mounted) return;

      setState(() {
        perfil = resultado;
        nombreController.text = resultado.nombre;
        biografiaController.text = resultado.biografia ?? '';
        errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorCarga = ApiConfig.mensajeError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> cambiarCorreo() async {
    final actualizado = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) {
        return DialogoCambiarCorreo(
          token: token,
          correoActual: perfil?.correo ?? '',
        );
      },
    );

    if (actualizado == null || !mounted) return;

    setState(() {
      perfil = actualizado;

      // Para que el menú lateral muestre el correo nuevo.
      usuarioActual['mail'] = actualizado.correo;
    });

    mostrarMensaje('Correo actualizado');
  }

  Future<void> cambiarPassword() async {
    final cambiada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DialogoCambiarPassword(token: token);
      },
    );

    if (cambiada != true || !mounted) return;

    mostrarMensaje('Contraseña actualizada');
  }

  Future<void> seleccionarFoto() async {
    try {
      final XFile? imagen = await selector.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagenNueva = imagen;
        imagenBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje('No se pudo seleccionar la fotografía');
    }
  }

  Future<void> guardar() async {
    if (nombreController.text.trim().length < 2) {
      mostrarMensaje('El nombre no puede quedar en blanco');
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final actualizado = await userService.actualizarMiPerfil(
        token: token,
        nombre: nombreController.text,
        biografia: biografiaController.text,
        imagen: imagenNueva,
      );

      if (!mounted) return;

      setState(() {
        perfil = actualizado;
        imagenNueva = null;
        imagenBytes = null;

        // Para que el menú lateral muestre el nombre nuevo.
        usuarioActual['nom_usr'] = actualizado.nombre;
      });

      mostrarMensaje('Perfil actualizado');
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

  Widget avatar(UserModel datos) {
    ImageProvider? imagen;

    if (imagenBytes != null) {
      imagen = MemoryImage(imagenBytes!);
    } else if (datos.foto != null && datos.foto!.trim().isNotEmpty) {
      imagen = NetworkImage(ApiConfig.urlImagen(datos.foto!.trim()));
    }

    return CircleAvatar(
      radius: 55,
      backgroundColor: AppColores.lima,
      backgroundImage: imagen,
      onBackgroundImageError: imagen == null ? null : (_, __) {},
      child: imagen == null
          ? Text(
              datos.nombre.isEmpty ? '?' : datos.nombre[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: AppColores.verde,
              ),
            )
          : null,
    );
  }

  Widget contenido() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final datos = perfil;

    if (datos == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorCarga ?? 'No se pudo cargar tu perfil.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColores.error),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          avatar(datos),

          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: seleccionarFoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Cambiar foto'),
          ),

          Text(
            '${datos.correo} · Miembro desde '
            '${ApiConfig.fechaCorta(datos.fechaRegistro)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColores.textoSuave),
          ),

          const SizedBox(height: 22),

          CustomTextField(
            controller: nombreController,
            label: 'Nombre',
            prefixIcon: Icons.badge_outlined,
            maxLength: 100,
          ),

          const SizedBox(height: 8),

          CustomTextField(
            controller: biografiaController,
            label: 'Biografía',
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
            maxLength: 300,
          ),

          const SizedBox(height: 16),

          PrimaryButton(
            text: guardando ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
            onPressed: guardando ? null : guardar,
          ),

          const SizedBox(height: 28),

          const Divider(),

          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Seguridad de la cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColores.verde,
                ),
              ),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: cambiarCorreo,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Cambiar correo'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: cambiarPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar contraseña'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),

      drawer: UserDrawer(
        usuario: usuarioActual,
        rutaActual: '/profile',
      ),

      body: contenido(),
    );
  }
}
