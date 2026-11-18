from sqlalchemy import (
    Column, Integer, String, Text,
    DateTime, ForeignKey, UniqueConstraint, func, text
)
from sqlalchemy.orm import relationship

from database import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    # 1 = administrador, 2 = usuario general
    tip_usu = Column(Integer, nullable=False, default=2)
    fecha_reg = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    # 1 = activo, 0 = dado de baja por un administrador
    activo = Column(Integer, nullable=False, default=1, server_default=text("1"))

    # Cada usuario tiene un perfil (relación 1 a 1 del diagrama de clases)
    perfil = relationship(
        "Perfil",
        back_populates="usuario",
        uselist=False,
        cascade="all, delete-orphan",
    )

    @property
    def biografia(self):
        return self.perfil.biografia if self.perfil else None

    @property
    def foto(self):
        return self.perfil.foto if self.perfil else None


class Perfil(Base):
    __tablename__ = "perfil"

    id_perfil = Column(Integer, primary_key=True, index=True)
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        unique=True,
        nullable=False,
    )
    biografia = Column(String(300), nullable=True)
    foto = Column(String(500), nullable=True)

    usuario = relationship("Usuario", back_populates="perfil")


class Categoria(Base):
    __tablename__ = "categoria"

    id_cat = Column(Integer, primary_key=True, index=True)
    nom_cat = Column(String(60), unique=True, nullable=False)


class Blog(Base):
    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    contenido = Column(Text, nullable=False)
    img = Column(String(500), nullable=True)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        nullable=False,
    )
    cat_id = Column(
        Integer,
        ForeignKey("categoria.id_cat"),
        nullable=False,
    )

    usuario = relationship("Usuario")
    categoria = relationship("Categoria")
    comentarios = relationship(
        "Comentario",
        cascade="all, delete-orphan",
    )
    valoraciones_db = relationship(
        "Valoracion",
        cascade="all, delete-orphan",
    )

    @property
    def autor(self):
        return self.usuario.nom_usr

    @property
    def nom_cat(self):
        return self.categoria.nom_cat


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        nullable=False,
    )
    blog_id = Column(
        Integer,
        ForeignKey("blog.id_blog"),
        nullable=False,
    )

    usuario = relationship("Usuario")
    reacciones_db = relationship(
        "ReaccionComentario",
        cascade="all, delete-orphan",
    )

    @property
    def autor(self):
        return self.usuario.nom_usr

# VALORACIÓN CON ESTRELLAS (opcional)
# Un usuario solo puede valorar una vez cada entrada.

class Valoracion(Base):
    __tablename__ = "valoracion"
    __table_args__ = (
        UniqueConstraint("blog_id", "usr_id", name="uq_valoracion_blog_usr"),
    )

    id_val = Column(Integer, primary_key=True, index=True)
    puntos = Column(Integer, nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        nullable=False,
    )
    blog_id = Column(
        Integer,
        ForeignKey("blog.id_blog"),
        nullable=False,
    )

# REACCIONES A COMENTARIOS (opcional)
# tipo: me_gusta, me_encanta, risa, asombro, tristeza, fuego

class ReaccionComentario(Base):
    __tablename__ = "reaccion_comentario"
    __table_args__ = (
        UniqueConstraint("com_id", "usr_id", "tipo", name="uq_reaccion_com_usr_tipo"),
    )

    id_rea = Column(Integer, primary_key=True, index=True)
    tipo = Column(String(20), nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        nullable=False,
    )
    com_id = Column(
        Integer,
        ForeignKey("comentarios.id_com"),
        nullable=False,
    )
