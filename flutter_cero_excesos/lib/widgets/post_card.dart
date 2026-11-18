import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/api_config.dart';
import 'app_colores.dart';
import 'star_rating.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  Widget imagenAlternativa() {
    return Container(
      height: 150,
      width: double.infinity,
      color: const Color(0xFFEEF1EA),
      child: const Center(
        child: Icon(
          Icons.eco_outlined,
          size: 56,
          color: AppColores.verdeMedio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneImagen =
        post.imagen != null && post.imagen!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tieneImagen)
              Image.network(
                ApiConfig.urlImagen(post.imagen!.trim()),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return imagenAlternativa();
                },
              )
            else
              imagenAlternativa(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.categoria.toUpperCase(),
                    style: const TextStyle(
                      color: AppColores.verdeMedio,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    post.titulo,
                    style: const TextStyle(
                      fontFamily: AppColores.fuenteTitulo,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColores.verde,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    post.contenido,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColores.textoSuave,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Promedio de estrellas
                  Row(
                    children: [
                      StarRating(valor: post.promedio, size: 18),

                      const SizedBox(width: 6),

                      Text(
                        post.totalValoraciones == 0
                            ? 'Sin valoraciones'
                            : '${post.promedio.toStringAsFixed(1)} '
                                '(${post.totalValoraciones})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColores.textoSuave,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: AppColores.textoSuave,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          '${post.autor} · ${ApiConfig.fechaCorta(post.fecha)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColores.textoSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
