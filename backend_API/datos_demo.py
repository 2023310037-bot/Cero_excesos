"""Carga usuarios y entradas de ejemplo (opcional).

Ejecutar una sola vez dentro de backend_API:   python datos_demo.py

Administrador:   admin@ceroexcesos.mx  /  Admin12345
Usuario normal:  demo@ceroexcesos.mx   /  Demo12345
"""
from pwdlib import PasswordHash
from sqlalchemy import select

from database import SessionLocal, inicializar_bd
from models import (
    Usuario, Perfil, Categoria, Blog, Comentario,
    Valoracion, ReaccionComentario,
)

password_hash = PasswordHash.recommended()

ENTRADAS = [
    ("Finanzas", "Un presupuesto semanal que sí se cumple",
     "Anota cuánto te llega cada semana y resta primero lo que no puedes mover: transporte y comida.\n\n"
     "Lo que sobra es tu dinero libre. Divídelo entre los siete días y revisa cada noche cuánto llevas gastado."),
    ("Fitness & Salud", "Rutina de 20 minutos sin gimnasio",
     "Con sentadillas, flexiones y plancha puedes entrenar casi todo el cuerpo.\n\n"
     "Haz tres rondas de cada ejercicio con 40 segundos de trabajo y 20 de descanso."),
    ("Hábitos Estudiantiles", "Cómo estudiar sin dejar todo para la noche anterior",
     "Divide cada materia en bloques de 25 minutos con 5 de descanso.\n\n"
     "Empieza por lo que menos te gusta: el resto del día se vuelve más ligero."),
    ("Estilo de Vida", "Cocinar para toda la semana en dos horas",
     "Cocina una base de arroz o pasta, una proteína y verduras asadas.\n\n"
     "Guárdalo en porciones y combina cada día con una salsa distinta."),
]


def crear_usuario(db, nombre, correo, contrasena, tipo):
    usuario = Usuario(
        nom_usr=nombre,
        mail=correo,
        pass_hash=password_hash.hash(contrasena),
        tip_usu=tipo,
    )
    usuario.perfil = Perfil()
    db.add(usuario)
    db.flush()
    return usuario


def main():
    inicializar_bd()

    with SessionLocal() as db:
        if db.scalars(select(Usuario).where(Usuario.mail == "demo@ceroexcesos.mx")).first():
            print("Los datos demo ya existen.")
            return

        admin = crear_usuario(db, "Administrador", "admin@ceroexcesos.mx", "Admin12345", 1)
        demo = crear_usuario(db, "Demo Cero Excesos", "demo@ceroexcesos.mx", "Demo12345", 2)

        primera = None
        puntuaciones = [5, 4, 5, 3]

        for nombre_cat, titulo, contenido in ENTRADAS:
            categoria = db.scalars(
                select(Categoria).where(Categoria.nom_cat == nombre_cat)
            ).first()

            publicacion = Blog(
                usr_id=demo.id_usr,
                cat_id=categoria.id_cat,
                titulo=titulo,
                contenido=contenido,
            )
            db.add(publicacion)
            db.flush()
            primera = primera or publicacion

            # El administrador valora las entradas de ejemplo.
            db.add(Valoracion(
                blog_id=publicacion.id_blog,
                usr_id=admin.id_usr,
                puntos=puntuaciones.pop(0),
            ))

        comentario = Comentario(
            comentario="¡Probé este método y sí funciona! 🎉",
            usr_id=demo.id_usr,
            blog_id=primera.id_blog,
            estatus=1,
        )
        db.add(comentario)
        db.flush()

        # Una reacción de ejemplo al comentario.
        db.add(ReaccionComentario(
            com_id=comentario.id_com,
            usr_id=admin.id_usr,
            tipo="me_gusta",
        ))

        db.commit()

    print("Listo. Usuario: demo@ceroexcesos.mx / Demo12345")
    print("Administrador: admin@ceroexcesos.mx / Admin12345")


if __name__ == "__main__":
    main()
