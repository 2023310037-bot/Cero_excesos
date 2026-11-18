from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

CORREO_PATRON = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"


# USUARIOS

class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150, pattern=CORREO_PATRON)
    password: str = Field(min_length=8, max_length=128)


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    tip_usu: int

    model_config = ConfigDict(from_attributes=True)


class LoginRequest(BaseModel):
    mail: str = Field(min_length=1, max_length=150)
    password: str = Field(min_length=1, max_length=128)


# PERFIL

class PerfilRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    tip_usu: int
    fecha_reg: datetime
    biografia: str | None = None
    foto: str | None = None

    model_config = ConfigDict(from_attributes=True)


class CambiarCorreo(BaseModel):
    mail: str = Field(min_length=5, max_length=150, pattern=CORREO_PATRON)
    password_actual: str = Field(min_length=1, max_length=128)


class CambiarPassword(BaseModel):
    password_actual: str = Field(min_length=1, max_length=128)
    password_nueva: str = Field(min_length=8, max_length=128)


# CATEGORÍAS

class CategoriaRespuesta(BaseModel):
    id_cat: int
    nom_cat: str

    model_config = ConfigDict(from_attributes=True)


# BLOG

class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    contenido: str
    img: str | None = None
    fecha: datetime
    usr_id: int
    autor: str
    cat_id: int
    nom_cat: str
    promedio: float = 0.0
    total_valoraciones: int = 0

    model_config = ConfigDict(from_attributes=True)


# VALORACIONES

class ValoracionCrear(BaseModel):
    puntos: int = Field(ge=1, le=5)


class ValoracionRespuesta(BaseModel):
    promedio: float
    total: int
    mi_puntuacion: int | None = None


# REACCIONES

class ReaccionCrear(BaseModel):
    tipo: str = Field(min_length=1, max_length=20)


class ReaccionResumen(BaseModel):
    tipo: str
    total: int
    mia: bool = False


# COMENTARIOS

class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1, max_length=1000)
    blog_id: int


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int
    autor: str
    reacciones: list[ReaccionResumen] = []

    model_config = ConfigDict(from_attributes=True)


# ADMINISTRACIÓN

class UsuarioAdminRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    tip_usu: int
    activo: bool
    fecha_reg: datetime

    model_config = ConfigDict(from_attributes=True)


class EstadoCambiar(BaseModel):
    activo: bool


class RolCambiar(BaseModel):
    tip_usu: int = Field(ge=1, le=2)
