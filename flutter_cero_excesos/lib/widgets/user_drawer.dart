import 'package:flutter/material.dart';

import 'app_colores.dart';

// Menú lateral. Si el usuario no ha iniciado sesión, muestra las
// opciones para entrar o crear una cuenta.
class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const UserDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  bool get haySesion {
    return (usuario['access_token']?.toString() ?? '').isNotEmpty;
  }

  String get nombre {
    return usuario['nom_usr']?.toString() ?? 'Invitado';
  }

  String get correo {
    return usuario['mail']?.toString() ?? 'Sin sesión iniciada';
  }

  bool get esAdmin {
    return (int.tryParse('${usuario['tip_usu']}') ?? 2) == 1;
  }

  void _navegar(BuildContext context, String ruta) {
    Navigator.pop(context);

    if (ruta == rutaActual) return;

    if (ruta == '/add-blog') {
      Navigator.pushNamed(context, ruta, arguments: usuario);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      ruta,
      arguments: usuario,
    );
  }

  void _cerrarSesion(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppColores.verde,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColores.lima,
                child: Text(
                  nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColores.verde,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            ),

            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Entradas'),
              selected: rutaActual == '/blog',
              onTap: () => _navegar(context, '/blog'),
            ),

            if (haySesion) ...[
              ListTile(
                leading: const Icon(Icons.post_add),
                title: const Text('Escribir entrada'),
                selected: rutaActual == '/add-blog',
                onTap: () => _navegar(context, '/add-blog'),
              ),

              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Mi perfil'),
                selected: rutaActual == '/profile',
                onTap: () => _navegar(context, '/profile'),
              ),

              if (esAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Administrar usuarios'),
                  selected: rutaActual == '/admin',
                  onTap: () => _navegar(context, '/admin'),
                ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar sesión'),
                onTap: () => _cerrarSesion(context),
              ),

              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Crear cuenta'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ],

            const Spacer(),

            if (haySesion) ...[
              const Divider(),

              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColores.error,
                ),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppColores.error),
                ),
                onTap: () => _cerrarSesion(context),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
