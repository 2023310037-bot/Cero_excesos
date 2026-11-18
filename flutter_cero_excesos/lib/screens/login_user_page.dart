import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/app_colores.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> iniciarSesion() async {
    final mensaje = authService.validarLogin(
      correo: correoController.text,
      password: passwordController.text,
    );

    if (mensaje != null) {
      mostrarMensaje(mensaje);
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final resultado = await authService.autenticar(
        correo: correoController.text,
        password: passwordController.text,
      );

      final String token = resultado['access_token']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception('El servidor no devolvió el token de acceso');
      }

      if (!mounted) return;

      // La sesión (token, nombre, rol...) viaja en los argumentos de la ruta.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/blog',
        (route) => false,
        arguments: resultado,
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
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColores.lima,
                        width: 3,
                      ),
                    ),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColores.verde,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'CERO EXCESOS',
                    style: TextStyle(
                      fontFamily: AppColores.fuenteTitulo,
                      fontSize: 24,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: AppColores.verde,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Inicia sesión para escribir y comentar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColores.textoSuave,
                    ),
                  ),

                  const SizedBox(height: 25),

                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.person,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña',
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

                  const SizedBox(height: 20),

                  PrimaryButton(
                    text: cargando ? 'VALIDANDO...' : 'INGRESAR',
                    onPressed: cargando ? null : iniciarSesion,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: cargando
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/register');
                              },
                        child: const Text('Registrarse'),
                      ),
                    ],
                  ),

                  // Leer el blog no requiere cuenta
                  TextButton(
                    onPressed: cargando
                        ? null
                        : () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/blog',
                              (route) => false,
                            );
                          },
                    child: const Text('Entrar sin iniciar sesión'),
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
