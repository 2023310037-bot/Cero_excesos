import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../services/api_config.dart';
import '../widgets/app_colores.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/user_drawer.dart';

// Solo para administradores: ver usuarios, darlos de baja/alta,
// cambiar su rol y crear nuevos administradores.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService adminService = AdminService();
  final TextEditingController busquedaController = TextEditingController();

  Map<String, dynamic> usuarioActual = {};
  bool argumentoLeido = false;

  List<UserModel> usuarios = [];
  bool cargando = true;
  String? error;

  String get token => usuarioActual['access_token']?.toString() ?? '';
  int get miId => int.tryParse('${usuarioActual['id_usr']}') ?? -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!argumentoLeido) {
      final argumento = ModalRoute.of(context)?.settings.arguments;

      if (argumento is Map) {
        usuarioActual = Map<String, dynamic>.from(argumento);
      }

      argumentoLeido = true;
      cargar();
    }
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final lista = await adminService.listarUsuarios(
        token: token,
        busqueda: busquedaController.text,
      );

      if (!mounted) return;

      setState(() {
        usuarios = lista;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = ApiConfig.mensajeError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<bool> confirmar(String titulo, String texto) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return resultado == true;
  }

  Future<void> alternarEstado(UserModel u) async {
    final darDeBaja = u.activo;

    final ok = await confirmar(
      darDeBaja ? 'Dar de baja' : 'Dar de alta',
      darDeBaja
          ? '${u.nombre} ya no podrá iniciar sesión. ¿Continuar?'
          : '${u.nombre} podrá volver a iniciar sesión. ¿Continuar?',
    );

    if (!ok) return;

    try {
      await adminService.cambiarEstado(
        token: token,
        idUsuario: u.id,
        activo: !u.activo,
      );

      mostrarMensaje(darDeBaja ? 'Usuario dado de baja' : 'Usuario dado de alta');
      await cargar();
    } catch (e) {
      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  Future<void> alternarRol(UserModel u) async {
    final hacerAdmin = u.tipoUsuario != 1;

    final ok = await confirmar(
      hacerAdmin ? 'Hacer administrador' : 'Quitar administrador',
      hacerAdmin
          ? '${u.nombre} tendrá permisos de administrador. ¿Continuar?'
          : '${u.nombre} volverá a ser usuario general. ¿Continuar?',
    );

    if (!ok) return;

    try {
      await adminService.cambiarRol(
        token: token,
        idUsuario: u.id,
        tipo: hacerAdmin ? 1 : 2,
      );

      mostrarMensaje('Rol actualizado');
      await cargar();
    } catch (e) {
      mostrarMensaje(ApiConfig.mensajeError(e));
    }
  }

  Future<void> nuevoAdministrador() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoNuevoAdmin(
        token: token,
        adminService: adminService,
      ),
    );

    if (creado == true) {
      mostrarMensaje('Administrador creado');
      await cargar();
    }
  }

  Widget etiqueta(String texto, {bool alerta = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: alerta ? AppColores.error : AppColores.verdeMedio,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          color: alerta ? AppColores.error : AppColores.verdeMedio,
        ),
      ),
    );
  }

  Widget filaUsuario(UserModel u) {
    final soyYo = u.id == miId;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColores.linea)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Row(
          children: [
            Flexible(
              child: Text(
                u.nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: u.activo ? AppColores.verde : AppColores.textoSuave,
                  decoration: u.activo ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (u.tipoUsuario == 1) etiqueta('Admin'),
            if (!u.activo) etiqueta('Baja', alerta: true),
            if (soyYo) etiqueta('Tú'),
          ],
        ),
        subtitle: Text(
          '${u.correo} · ${ApiConfig.fechaCorta(u.fechaRegistro)}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: soyYo
            ? null
            : PopupMenuButton<String>(
                onSelected: (valor) {
                  if (valor == 'estado') alternarEstado(u);
                  if (valor == 'rol') alternarRol(u);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'estado',
                    child: Text(u.activo ? 'Dar de baja' : 'Dar de alta'),
                  ),
                  PopupMenuItem(
                    value: 'rol',
                    child: Text(
                      u.tipoUsuario == 1
                          ? 'Quitar administrador'
                          : 'Hacer administrador',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),

      drawer: UserDrawer(usuario: usuarioActual, rutaActual: '/admin'),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: nuevoAdministrador,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo administrador'),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: busquedaController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => cargar(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    busquedaController.clear();
                    cargar();
                  },
                ),
              ),
            ),
          ),

          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!, textAlign: TextAlign.center),
                        ),
                      )
                    : usuarios.isEmpty
                        ? const Center(child: Text('No hay usuarios.'))
                        : RefreshIndicator(
                            onRefresh: cargar,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: usuarios.length,
                              itemBuilder: (context, i) =>
                                  filaUsuario(usuarios[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DialogoNuevoAdmin extends StatefulWidget {
  final String token;
  final AdminService adminService;

  const _DialogoNuevoAdmin({
    required this.token,
    required this.adminService,
  });

  @override
  State<_DialogoNuevoAdmin> createState() => _DialogoNuevoAdminState();
}

class _DialogoNuevoAdminState extends State<_DialogoNuevoAdmin> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  bool guardando = false;
  String? error;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text;

    if (nombre.length < 2 || !correo.contains('@') || !correo.contains('.')) {
      setState(() => error = 'Escribe un nombre y un correo válidos');
      return;
    }

    if (password.length < 8) {
      setState(() => error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() {
      guardando = true;
      error = null;
    });

    try {
      await widget.adminService.crearAdministrador(
        token: widget.token,
        nombre: nombre,
        correo: correo,
        password: password,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
        error = ApiConfig.mensajeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo administrador'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nombreController,
                label: 'Nombre',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: correoController,
                label: 'Correo electrónico',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: passwordController,
                label: 'Contraseña (mín. 8)',
                prefixIcon: Icons.key_outlined,
                obscureText: true,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: AppColores.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: guardando ? null : guardar,
          child: Text(guardando ? 'Guardando...' : 'Crear'),
        ),
      ],
    );
  }
}
