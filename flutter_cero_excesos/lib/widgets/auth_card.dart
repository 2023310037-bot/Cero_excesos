import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // En pantallas angostas la tarjeta se ajusta para no desbordarse.
    final anchoPantalla = MediaQuery.of(context).size.width;
    final anchoTarjeta = anchoPantalla > 440 ? 340.0 : anchoPantalla - 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: anchoTarjeta,
          child: child,
        ),
      ),
    );
  }
}
