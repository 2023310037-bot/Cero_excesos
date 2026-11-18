import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/user_service.dart';
import 'app_colores.dart';
import 'custom_text_field.dart';

// Ventana para cambiar la contraseña. Regresa true cuando se guardó.
class DialogoCambiarPassword extends StatefulWidget {
  final String token;

  const DialogoCambiarPassword({
    super.key,
    required this.token,
  });

  @override
  State<DialogoCambiarPassword> createState() =>
      _DialogoCambiarPasswordState();
}

class _DialogoCambiarPasswordState extends State<DialogoCambiarPassword> {
  final TextEditingController actualController = TextEditingController();
  final TextEditingController nuevaController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  final UserService userService = UserService();

  bool guardando = false;
  bool ocultarPassword = true;
  String? error;

  @override
  void dispose() {
    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (actualController.text.isEmpty ||
        nuevaController.text.isEmpty ||
        confirmarController.text.isEmpty) {
      setState(() {
        error = 'Por favor ingrese todos los campos';
      });
      return;
    }

    if (nuevaController.text.length < 8) {
      setState(() {
        error = 'La contraseña nueva debe tener al menos 8 caracteres';
      });
      return;
    }

    if (nuevaController.text != confirmarController.text) {
      setState(() {
        error = 'Las contraseñas nuevas no coinciden';
      });
      return;
    }

    setState(() {
      guardando = true;
      error = null;
    });

    try {
      await userService.cambiarPassword(
        token: widget.token,
        passwordActual: actualController.text,
        passwordNueva: nuevaController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
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
      title: const Text('Cambiar contraseña'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: actualController,
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

            const SizedBox(height: 12),

            CustomTextField(
              controller: nuevaController,
              label: 'Contraseña nueva (mínimo 8)',
              prefixIcon: Icons.lock_outline,
              obscureText: ocultarPassword,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              controller: confirmarController,
              label: 'Confirmar contraseña nueva',
              prefixIcon: Icons.lock_outline,
              obscureText: ocultarPassword,
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
