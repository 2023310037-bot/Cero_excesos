import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/user_service.dart';
import 'app_colores.dart';
import 'custom_text_field.dart';

// Ventana para cambiar el correo. Al terminar regresa el perfil
// actualizado (UserModel) con Navigator.pop.
class DialogoCambiarCorreo extends StatefulWidget {
  final String token;
  final String correoActual;

  const DialogoCambiarCorreo({
    super.key,
    required this.token,
    required this.correoActual,
  });

  @override
  State<DialogoCambiarCorreo> createState() => _DialogoCambiarCorreoState();
}

class _DialogoCambiarCorreoState extends State<DialogoCambiarCorreo> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final UserService userService = UserService();

  bool guardando = false;
  bool ocultarPassword = true;
  String? error;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final correo = correoController.text.trim();

    if (!correo.contains('@') || !correo.contains('.')) {
      setState(() {
        error = 'Ingresa un correo válido';
      });
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        error = 'Escribe tu contraseña actual';
      });
      return;
    }

    setState(() {
      guardando = true;
      error = null;
    });

    try {
      final actualizado = await userService.cambiarCorreo(
        token: widget.token,
        nuevoCorreo: correo,
        passwordActual: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, actualizado);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = ApiConfig.mensajeError(e);
        guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar correo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correo actual: ${widget.correoActual}',
              style: const TextStyle(color: AppColores.textoSuave),
            ),

            const SizedBox(height: 14),

            CustomTextField(
              controller: correoController,
              label: 'Correo nuevo',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: passwordController,
              label: 'Contraseña actual',
              prefixIcon: Icons.key_outlined,
              obscureText: ocultarPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  ocultarPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    ocultarPassword = !ocultarPassword;
                  });
                },
              ),
            ),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: AppColores.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),

        ElevatedButton(
          onPressed: guardando ? null : guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColores.verde,
            foregroundColor: Colors.white,
          ),
          child: Text(guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
