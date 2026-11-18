import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> registrar() async {
    final mensaje = authService.validarRegistro(
      nombre: nombreController.text,
      correo: correoController.text,
      password: passwordController.text,
      confirmarPassword: confirmarController.text,
    );

    if (mensaje != null) {
      mostrarMensaje(mensaje);
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await authService.registrarUsuario(
        nombre: nombreController.text,
        correo: correoController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      mostrarMensaje('Cuenta creada. Ahora inicia sesión.');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(ApiConfig.mensajeError(e));
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 60,
                    color: AppColores.verdeMedio,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'CREAR CUENTA',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColores.verde,
                    ),
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
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña (mínimo 8)',
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

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: confirmarController,
                    label: 'Confirmar contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: ocultarPassword,
                  ),

                  const SizedBox(height: 22),

                  PrimaryButton(
                    text: cargando ? 'REGISTRANDO...' : 'REGISTRARSE',
                    onPressed: cargando ? null : registrar,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes cuenta?'),
                      TextButton(
                        onPressed: cargando
                            ? null
                            : () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              },
                        child: const Text('Iniciar sesión'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
