import logging
import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from logging.handlers import RotatingFileHandler
from pathlib import Path

import jwt
from dotenv import load_dotenv

from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    Request,
    UploadFile,
    File,
    Form,
)
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import (
    HTTPBearer,
    HTTPAuthorizationCredentials,
)
from fastapi.staticfiles import StaticFiles

from sqlalchemy import func, select, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from pwdlib import PasswordHash

from database import inicializar_bd, obtener_sesion
from models import (
    Usuario, Perfil, Categoria, Blog, Comentario,
    Valoracion, ReaccionComentario,
)

from schemas import (
    UsuarioCrear,
    UsuarioRespuesta,
    LoginRequest,
    PerfilRespuesta,
    CategoriaRespuesta,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    CambiarCorreo,
    CambiarPassword,
    ValoracionCrear,
    ValoracionRespuesta,
    ReaccionCrear,
    ReaccionResumen,
    UsuarioAdminRespuesta,
    EstadoCambiar,
    RolCambiar,
)


# ==========================================
# CONFIGURACIÓN
# ==========================================

load_dotenv()

password_hash = PasswordHash.recommended()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")

if not SECRET_KEY:
    raise RuntimeError(
        "No se encontró JWT_SECRET_KEY en el archivo .env"
    )

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 120

ROL_ADMIN = 1

# Reacciones permitidas en los comentarios (la app las muestra como emojis).
REACCIONES_PERMITIDAS = [
    "me_gusta",
    "me_encanta",
    "risa",
    "asombro",
    "tristeza",
    "fuego",
]

security = HTTPBearer(auto_error=False)

# Carpeta donde se almacenan las fotografías (entradas y perfiles).
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5 MB
EXTENSIONES_PERMITIDAS = {".jpg", ".jpeg", ".png", ".webp"}

# Por si el celular o el navegador no manda la extensión en el nombre.
EXTENSION_POR_TIPO = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

CARPETA_LOGS = Path("logs")
CARPETA_LOGS.mkdir(parents=True, exist_ok=True)

logger = logging.getLogger("cero_excesos")
logger.setLevel(logging.INFO)

if not logger.handlers:
    manejador = RotatingFileHandler(
        CARPETA_LOGS / "errores.log",
        maxBytes=500_000,
        backupCount=3,
        encoding="utf-8",
    )
    manejador.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    )
    logger.addHandler(manejador)


# CREACIÓN DE TOKEN

def crear_token(usuario: Usuario):
    fecha_actual = datetime.now(timezone.utc)

    datos_token = {
        "sub": str(usuario.id_usr),
        "rol": usuario.tip_usu,
        "exp": fecha_actual + timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        ),
    }

    token = jwt.encode(
        datos_token,
        SECRET_KEY,
        algorithm=ALGORITHM,
    )

    return token


# VERIFICAR USUARIO AUTENTICADO

def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(obtener_sesion),
):
    if credenciales is None:
        raise HTTPException(
            status_code=401,
            detail="Debes iniciar sesión para hacer esto",
        )

    try:
        datos = jwt.decode(
            credenciales.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )

        usuario_id = int(datos.get("sub"))
        rol_token = int(datos.get("rol"))

    except (jwt.InvalidTokenError, TypeError, ValueError):
        raise HTTPException(
            status_code=401,
            detail="Tu sesión expiró. Inicia sesión nuevamente",
        )

    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=401,
            detail="Usuario no encontrado",
        )

    if usuario.activo != 1:
        raise HTTPException(
            status_code=403,
            detail="Tu cuenta fue dada de baja. Contacta a un administrador",
        )

    if usuario.tip_usu != rol_token:
        raise HTTPException(
            status_code=401,
            detail="Los permisos del usuario han cambiado. Inicia sesión nuevamente",
        )

    return usuario


def obtener_admin(usuario: Usuario = Depends(obtener_usuario_actual)):
    if usuario.tip_usu != 1:
        raise HTTPException(
            status_code=403,
            detail="Solo un administrador puede hacer esto",
        )

    return usuario

def obtener_usuario_opcional(
    credenciales: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(obtener_sesion),
):
    if credenciales is None:
        return None

    try:
        return obtener_usuario_actual(credenciales, db)
    except HTTPException:
        return None


# FUNCIONES PARA FOTOGRAFÍAS

async def guardar_imagen(imagen: UploadFile) -> str:
    extension = Path(imagen.filename or "").suffix.lower()

    if extension not in EXTENSIONES_PERMITIDAS:
        extension = EXTENSION_POR_TIPO.get(
            (imagen.content_type or "").lower(),
            "",
        )

    if extension not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(
            status_code=415,
            detail="Formato no permitido. Usa JPG, JPEG, PNG o WEBP",
        )

    contenido = await imagen.read()

    if not contenido:
        raise HTTPException(
            status_code=422,
            detail="La fotografía está vacía",
        )

    if len(contenido) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=413,
            detail="La fotografía no debe superar los 5 MB",
        )

    # Nombre único para no sobrescribir otras imágenes.
    nombre_archivo = f"{uuid.uuid4().hex}{extension}"
    (UPLOAD_DIR / nombre_archivo).write_bytes(contenido)

    return f"/uploads/{nombre_archivo}"


def borrar_imagen(ruta: str | None):
    # Elimina el archivo de una fotografía guardada (si existe).
    if not ruta or not ruta.startswith("/uploads/"):
        return

    archivo = UPLOAD_DIR / Path(ruta).name

    if archivo.exists():
        archivo.unlink()


def hay_archivo(imagen: UploadFile | None) -> bool:
    return imagen is not None and bool(imagen.filename)


# INICIO DE FASTAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Crea la base de datos, las tablas y las categorías iniciales.
    inicializar_bd()
    yield


app = FastAPI(
    title="API de Cero Excesos",
    lifespan=lifespan,
)

# Permite consultar las imágenes mediante /uploads/nombre_archivo.
app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOAD_DIR)),
    name="uploads",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# MANEJO DE ERRORES

@app.exception_handler(RequestValidationError)
async def error_de_validacion(request: Request, error: RequestValidationError):
    # Convierte el error de FastAPI en un mensaje corto para la app.
    detalle = "Datos no válidos"

    errores = error.errors()

    if errores:
        campos = [
            str(parte)
            for parte in errores[0].get("loc", [])
            if parte not in ("body", "form", "query", "path")
        ]
        campo = ".".join(campos)

        if campo:
            detalle = f"Revisa el campo «{campo}»"

    return JSONResponse(status_code=422, content={"detail": detalle})


@app.exception_handler(Exception)
async def error_inesperado(request: Request, error: Exception):
    # RNF-004: se guarda el error completo en logs/errores.log
    logger.error(
        "Error no controlado en %s %s",
        request.method,
        request.url.path,
        exc_info=error,
    )

    return JSONResponse(
        status_code=500,
        content={
            "detail": "Ocurrió un error en el servidor. Intenta de nuevo."
        },
    )


@app.get("/")
def inicio():
    return {
        "mensaje": "API de Cero Excesos funcionando correctamente"
    }


# ==========================================
# RF002: INICIO DE SESIÓN
# ==========================================

@app.post("/login")
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    usuario = db.scalars(
        select(Usuario).where(
            Usuario.mail == correo
        )
    ).first()

    # Mismo mensaje si el correo no existe o la contraseña falla.
    if usuario is None:
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    try:
        contraseña_correcta = password_hash.verify(
            datos.password,
            usuario.pass_hash,
        )
    except (ValueError, TypeError):
        contraseña_correcta = False

    if not contraseña_correcta:
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    if usuario.activo != 1:
        raise HTTPException(
            status_code=403,
            detail="Tu cuenta fue dada de baja. Contacta a un administrador",
        )

    return {
        "access_token": crear_token(usuario),
        "token_type": "bearer",
        "id_usr": usuario.id_usr,
        "nom_usr": usuario.nom_usr,
        "mail": usuario.mail,
        "tip_usu": usuario.tip_usu,
    }

@app.post(
    "/usuarios",
    response_model=UsuarioRespuesta,
    status_code=201,
)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
):
    nombre = datos.nom_usr.strip()

    if len(nombre) < 2:
        raise HTTPException(
            status_code=422,
            detail="El nombre debe tener al menos 2 caracteres",
        )

    usuario = Usuario(
        nom_usr=nombre,
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        tip_usu=2,
    )

    # Cada usuario nace con su perfil vacío.
    usuario.perfil = Perfil()

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.get(
    "/perfil/me",
    response_model=PerfilRespuesta,
)
def consultar_mi_perfil(
    usuario: Usuario = Depends(obtener_usuario_actual),
):
    return usuario


@app.put(
    "/perfil/me",
    response_model=PerfilRespuesta,
)
async def actualizar_mi_perfil(
    nom_usr: str = Form(...),
    biografia: str | None = Form(None),
    imagen: UploadFile | None = File(None),
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    nom_usr = nom_usr.strip()
    biografia = (biografia or "").strip()

    if len(nom_usr) < 2:
        raise HTTPException(
            status_code=422,
            detail="El nombre no puede quedar en blanco",
        )

    if len(nom_usr) > 100:
        raise HTTPException(
            status_code=422,
            detail="El nombre no puede pasar de 100 caracteres",
        )

    if len(biografia) > 300:
        raise HTTPException(
            status_code=422,
            detail="La biografía no puede pasar de 300 caracteres",
        )

    foto_nueva = None

    if hay_archivo(imagen):
        foto_nueva = await guardar_imagen(imagen)

    if usuario.perfil is None:
        usuario.perfil = Perfil()

    foto_anterior = usuario.perfil.foto

    usuario.nom_usr = nom_usr
    usuario.perfil.biografia = biografia

    if foto_nueva:
        usuario.perfil.foto = foto_nueva

    try:
        db.commit()
        db.refresh(usuario)

    except Exception:
        db.rollback()
        borrar_imagen(foto_nueva)

        logger.error("No se pudo actualizar el perfil", exc_info=True)

        raise HTTPException(
            status_code=500,
            detail="No se pudo actualizar el perfil",
        )

    if foto_nueva:
        borrar_imagen(foto_anterior)

    return usuario


# ==========================================
# RF005: CATEGORÍAS
# ==========================================

@app.get(
    "/categorias",
    response_model=list[CategoriaRespuesta],
)
def listar_categorias(
    db: Session = Depends(obtener_sesion),
):
    return db.scalars(
        select(Categoria).order_by(Categoria.id_cat)
    ).all()


def validar_datos_blog(
    titulo: str,
    contenido: str,
    cat_id: int,
    db: Session,
):
    titulo = titulo.strip()
    contenido = contenido.strip()

    if not titulo:
        raise HTTPException(
            status_code=422,
            detail="El título no puede estar vacío",
        )

    if len(titulo) > 150:
        raise HTTPException(
            status_code=422,
            detail="El título no puede pasar de 150 caracteres",
        )

    if not contenido:
        raise HTTPException(
            status_code=422,
            detail="El contenido no puede estar vacío",
        )

    # Todo artículo debe tener una categoría válida.
    if db.get(Categoria, cat_id) is None:
        raise HTTPException(
            status_code=422,
            detail="La categoría seleccionada no existe",
        )

    return titulo, contenido


def obtener_blog_o_404(db: Session, blog_id: int) -> Blog:
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion


def adjuntar_valoraciones(db: Session, publicaciones: list):
    # Agrega a cada entrada su promedio de estrellas (una sola consulta).
    ids = [p.id_blog for p in publicaciones]
    resumen = {}

    if ids:
        filas = db.execute(
            select(
                Valoracion.blog_id,
                func.avg(Valoracion.puntos),
                func.count(Valoracion.id_val),
            )
            .where(Valoracion.blog_id.in_(ids))
            .group_by(Valoracion.blog_id)
        ).all()

        resumen = {
            blog_id: (float(promedio), int(total))
            for blog_id, promedio, total in filas
        }

    for publicacion in publicaciones:
        promedio, total = resumen.get(publicacion.id_blog, (0.0, 0))
        publicacion.promedio = round(promedio, 1)
        publicacion.total_valoraciones = total

    return publicaciones


def resumen_valoracion(db: Session, blog_id: int, usuario: Usuario | None):
    promedio, total = db.execute(
        select(
            func.avg(Valoracion.puntos),
            func.count(Valoracion.id_val),
        ).where(Valoracion.blog_id == blog_id)
    ).one()

    mi_puntuacion = None

    if usuario is not None:
        mi_puntuacion = db.scalar(
            select(Valoracion.puntos).where(
                Valoracion.blog_id == blog_id,
                Valoracion.usr_id == usuario.id_usr,
            )
        )

    return {
        "promedio": round(float(promedio or 0), 1),
        "total": int(total or 0),
        "mi_puntuacion": mi_puntuacion,
    }


def adjuntar_reacciones(
    db: Session,
    comentarios: list,
    usuario: Usuario | None,
):
    # Agrega a cada comentario sus reacciones (cuántas y cuáles son mías).
    ids = [c.id_com for c in comentarios]
    por_comentario = {i: {} for i in ids}

    if ids:
        filas = db.execute(
            select(
                ReaccionComentario.com_id,
                ReaccionComentario.tipo,
                func.count(ReaccionComentario.id_rea),
            )
            .where(ReaccionComentario.com_id.in_(ids))
            .group_by(ReaccionComentario.com_id, ReaccionComentario.tipo)
        ).all()

        for com_id, tipo, total in filas:
            por_comentario[com_id][tipo] = {
                "tipo": tipo,
                "total": int(total),
                "mia": False,
            }

        if usuario is not None:
            mias = db.execute(
                select(
                    ReaccionComentario.com_id,
                    ReaccionComentario.tipo,
                ).where(
                    ReaccionComentario.com_id.in_(ids),
                    ReaccionComentario.usr_id == usuario.id_usr,
                )
            ).all()

            for com_id, tipo in mias:
                if tipo in por_comentario[com_id]:
                    por_comentario[com_id][tipo]["mia"] = True

    for comentario in comentarios:
        resumen = por_comentario[comentario.id_com]

        comentario.reacciones = [
            resumen[tipo]
            for tipo in REACCIONES_PERMITIDAS
            if tipo in resumen
        ]

    return comentarios


@app.post(
    "/blog",
    response_model=BlogRespuesta,
    status_code=201,
)
async def crear_blog(
    titulo: str = Form(...),
    contenido: str = Form(...),
    cat_id: int = Form(...),
    imagen: UploadFile | None = File(None),
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    titulo, contenido = validar_datos_blog(titulo, contenido, cat_id, db)

    ruta_imagen = None

    if hay_archivo(imagen):
        ruta_imagen = await guardar_imagen(imagen)

    publicacion = Blog(
        usr_id=usuario.id_usr,
        cat_id=cat_id,
        titulo=titulo,
        contenido=contenido,
        img=ruta_imagen,
    )

    try:
        db.add(publicacion)
        db.commit()
        db.refresh(publicacion)

    except Exception:
        db.rollback()

        # Si falla el registro, se elimina la fotografía para no dejar
        # archivos sin publicación.
        borrar_imagen(ruta_imagen)

        logger.error("No se pudo guardar la publicación", exc_info=True)

        raise HTTPException(
            status_code=500,
            detail="No se pudo guardar la publicación",
        )

    return adjuntar_valoraciones(db, [publicacion])[0]


@app.get(
    "/blog",
    response_model=list[BlogRespuesta],
)
def listar_blog(
    cat_id: int | None = None,
    usr_id: int | None = None,
    q: str | None = None,
    db: Session = Depends(obtener_sesion),
):
    consulta = (
        select(Blog)
        .options(
            joinedload(Blog.usuario),
            joinedload(Blog.categoria),
        )
        # Cronológico: lo más reciente primero.
        .order_by(Blog.fecha.desc(), Blog.id_blog.desc())
    )

    # RF005: filtrar por categoría.
    if cat_id is not None:
        consulta = consulta.where(Blog.cat_id == cat_id)

    # "Mis entradas": solo las publicaciones de un usuario.
    if usr_id is not None:
        consulta = consulta.where(Blog.usr_id == usr_id)

    if q and q.strip():
        patron = f"%{q.strip()}%"

        consulta = consulta.where(
            or_(
                Blog.titulo.like(patron),
                Blog.contenido.like(patron),
            )
        )

    return adjuntar_valoraciones(db, db.scalars(consulta).all())


@app.get(
    "/blog/{blog_id}",
    response_model=BlogRespuesta,
)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    return adjuntar_valoraciones(db, [obtener_blog_o_404(db, blog_id)])[0]


@app.put(
    "/blog/{blog_id}",
    response_model=BlogRespuesta,
)
async def editar_blog(
    blog_id: int,
    titulo: str = Form(...),
    contenido: str = Form(...),
    cat_id: int = Form(...),
    imagen: UploadFile | None = File(None),
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    publicacion = obtener_blog_o_404(db, blog_id)

    if publicacion.usr_id != usuario.id_usr:
        raise HTTPException(
            status_code=403,
            detail="Solo puedes editar tus propias publicaciones",
        )

    titulo, contenido = validar_datos_blog(titulo, contenido, cat_id, db)

    imagen_nueva = None

    if hay_archivo(imagen):
        imagen_nueva = await guardar_imagen(imagen)

    imagen_anterior = publicacion.img

    publicacion.titulo = titulo
    publicacion.contenido = contenido
    publicacion.cat_id = cat_id

    if imagen_nueva:
        publicacion.img = imagen_nueva

    try:
        db.commit()
        db.refresh(publicacion)

    except Exception:
        db.rollback()
        borrar_imagen(imagen_nueva)

        logger.error("No se pudo actualizar la publicación", exc_info=True)

        raise HTTPException(
            status_code=500,
            detail="No se pudo actualizar la publicación",
        )

    if imagen_nueva:
        borrar_imagen(imagen_anterior)

    return adjuntar_valoraciones(db, [publicacion])[0]


@app.delete("/blog/{blog_id}")
def eliminar_blog(
    blog_id: int,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    publicacion = obtener_blog_o_404(db, blog_id)

    # El autor puede borrar su entrada; el administrador puede moderar.
    es_autor = publicacion.usr_id == usuario.id_usr
    es_admin = usuario.tip_usu == ROL_ADMIN

    if not es_autor and not es_admin:
        raise HTTPException(
            status_code=403,
            detail="Solo puedes eliminar tus propias publicaciones",
        )

    imagen = publicacion.img

    # Sus comentarios se eliminan junto con la publicación.
    db.delete(publicacion)
    db.commit()

    borrar_imagen(imagen)

    return {"mensaje": "Publicación eliminada correctamente"}


@app.get(
    "/blog/{blog_id}/comentarios",
    response_model=list[ComentarioRespuesta],
)
def comentarios_por_blog(
    blog_id: int,
    usuario: Usuario | None = Depends(obtener_usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    obtener_blog_o_404(db, blog_id)

    comentarios = db.scalars(
        select(Comentario)
        .options(joinedload(Comentario.usuario))
        .where(
            Comentario.blog_id == blog_id,
            Comentario.estatus == 1,
        )
        .order_by(Comentario.fecha, Comentario.id_com)
    ).all()

    return adjuntar_reacciones(db, comentarios, usuario)


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    datos: ComentarioCrear,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    texto = datos.comentario.strip()

    if not texto:
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    obtener_blog_o_404(db, datos.blog_id)

    
    nuevo = Comentario(
        comentario=texto,
        usr_id=usuario.id_usr,
        blog_id=datos.blog_id,
        estatus=1,
    )

    try:
        db.add(nuevo)
        db.commit()
        db.refresh(nuevo)

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail="No se pudo guardar el comentario",
        )

    nuevo.reacciones = []

    return nuevo


@app.post(
    "/comentarios/{com_id}/reaccion",
    response_model=list[ReaccionResumen],
)
def reaccionar_comentario(
    com_id: int,
    datos: ReaccionCrear,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    # Si ya reaccionaste con ese emoji, se quita; si no, se agrega.
    if datos.tipo not in REACCIONES_PERMITIDAS:
        raise HTTPException(
            status_code=422,
            detail="La reacción no es válida",
        )

    comentario = db.get(Comentario, com_id)

    if comentario is None or comentario.estatus != 1:
        raise HTTPException(
            status_code=404,
            detail="Comentario no encontrado",
        )

    existente = db.scalars(
        select(ReaccionComentario).where(
            ReaccionComentario.com_id == com_id,
            ReaccionComentario.usr_id == usuario.id_usr,
            ReaccionComentario.tipo == datos.tipo,
        )
    ).first()

    try:
        if existente is not None:
            db.delete(existente)
        else:
            db.add(
                ReaccionComentario(
                    com_id=com_id,
                    usr_id=usuario.id_usr,
                    tipo=datos.tipo,
                )
            )

        db.commit()

    except IntegrityError:
        db.rollback()

    adjuntar_reacciones(db, [comentario], usuario)

    return comentario.reacciones

@app.get(
    "/blog/{blog_id}/valoracion",
    response_model=ValoracionRespuesta,
)
def consultar_valoracion(
    blog_id: int,
    usuario: Usuario | None = Depends(obtener_usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    obtener_blog_o_404(db, blog_id)

    return resumen_valoracion(db, blog_id, usuario)


@app.post(
    "/blog/{blog_id}/valoracion",
    response_model=ValoracionRespuesta,
)
def valorar_blog(
    blog_id: int,
    datos: ValoracionCrear,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    publicacion = obtener_blog_o_404(db, blog_id)

    # Evita que alguien se califique a sí mismo.
    if publicacion.usr_id == usuario.id_usr:
        raise HTTPException(
            status_code=403,
            detail="No puedes valorar tu propia entrada",
        )

    existente = db.scalars(
        select(Valoracion).where(
            Valoracion.blog_id == blog_id,
            Valoracion.usr_id == usuario.id_usr,
        )
    ).first()

    # Una persona tiene una sola valoración por entrada: si vuelve a
    # calificar, se actualiza la anterior.
    if existente is not None:
        existente.puntos = datos.puntos
    else:
        db.add(
            Valoracion(
                blog_id=blog_id,
                usr_id=usuario.id_usr,
                puntos=datos.puntos,
            )
        )

    try:
        db.commit()

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail="No se pudo guardar la valoración",
        )

    return resumen_valoracion(db, blog_id, usuario)


def confirmar_contrasena_actual(usuario: Usuario, contrasena: str):
    try:
        correcta = password_hash.verify(contrasena, usuario.pass_hash)
    except (ValueError, TypeError):
        correcta = False

    if not correcta:
        raise HTTPException(
            status_code=400,
            detail="La contraseña actual es incorrecta",
        )


@app.put(
    "/perfil/me/correo",
    response_model=PerfilRespuesta,
)
def cambiar_correo(
    datos: CambiarCorreo,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    confirmar_contrasena_actual(usuario, datos.password_actual)

    correo_nuevo = datos.mail.strip().lower()

    if correo_nuevo == usuario.mail:
        raise HTTPException(
            status_code=422,
            detail="El correo nuevo es igual al actual",
        )

    usuario.mail = correo_nuevo

    try:
        db.commit()
        db.refresh(usuario)

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.put("/perfil/me/password")
def cambiar_password(
    datos: CambiarPassword,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    confirmar_contrasena_actual(usuario, datos.password_actual)

    if datos.password_nueva == datos.password_actual:
        raise HTTPException(
            status_code=422,
            detail="La contraseña nueva debe ser diferente a la actual",
        )

    usuario.pass_hash = password_hash.hash(datos.password_nueva)
    db.commit()

    return {"mensaje": "Contraseña actualizada correctamente"}



# ==========================================
# ELIMINAR COMENTARIOS
# Lo puede hacer el autor o un administrador (moderación).
# Se marca estatus = 0 y deja de mostrarse.
# ==========================================

@app.delete("/comentarios/{com_id}")
def eliminar_comentario(
    com_id: int,
    usuario: Usuario = Depends(obtener_usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    comentario = db.get(Comentario, com_id)

    if comentario is None or comentario.estatus != 1:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    if usuario.tip_usu != 1 and comentario.usr_id != usuario.id_usr:
        raise HTTPException(
            status_code=403,
            detail="No puedes eliminar este comentario",
        )

    comentario.estatus = 0
    db.commit()

    logger.info(
        "Comentario %s eliminado por usuario %s", com_id, usuario.id_usr
    )

    return {"mensaje": "Comentario eliminado"}


# ==========================================
# ADMINISTRACIÓN DE USUARIOS
# ==========================================

@app.get(
    "/admin/usuarios",
    response_model=list[UsuarioAdminRespuesta],
)
def listar_usuarios(
    q: str | None = None,
    admin: Usuario = Depends(obtener_admin),
    db: Session = Depends(obtener_sesion),
):
    consulta = select(Usuario).order_by(Usuario.tip_usu, Usuario.nom_usr)

    if q and q.strip():
        patron = f"%{q.strip()}%"
        consulta = consulta.where(
            or_(Usuario.nom_usr.like(patron), Usuario.mail.like(patron))
        )

    return [
        UsuarioAdminRespuesta(
            id_usr=u.id_usr,
            nom_usr=u.nom_usr,
            mail=u.mail,
            tip_usu=u.tip_usu,
            activo=u.activo == 1,
            fecha_reg=u.fecha_reg,
        )
        for u in db.scalars(consulta).all()
    ]


def usuario_admin_o_404(db: Session, id_usr: int, admin: Usuario) -> Usuario:
    objetivo = db.get(Usuario, id_usr)

    if objetivo is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if objetivo.id_usr == admin.id_usr:
        raise HTTPException(
            status_code=400,
            detail="No puedes cambiar tu propia cuenta desde aquí",
        )

    return objetivo


@app.put("/admin/usuarios/{id_usr}/estado")
def cambiar_estado_usuario(
    id_usr: int,
    datos: EstadoCambiar,
    admin: Usuario = Depends(obtener_admin),
    db: Session = Depends(obtener_sesion),
):
    objetivo = usuario_admin_o_404(db, id_usr, admin)
    objetivo.activo = 1 if datos.activo else 0
    db.commit()

    logger.info(
        "Admin %s %s al usuario %s",
        admin.id_usr, "dio de alta" if datos.activo else "dio de baja", id_usr,
    )

    return {"mensaje": "Usuario activado" if datos.activo else "Usuario dado de baja"}


@app.put("/admin/usuarios/{id_usr}/rol")
def cambiar_rol_usuario(
    id_usr: int,
    datos: RolCambiar,
    admin: Usuario = Depends(obtener_admin),
    db: Session = Depends(obtener_sesion),
):
    objetivo = usuario_admin_o_404(db, id_usr, admin)
    objetivo.tip_usu = datos.tip_usu
    db.commit()

    logger.info("Admin %s cambió el rol del usuario %s a %s", admin.id_usr, id_usr, datos.tip_usu)

    return {"mensaje": "Rol actualizado"}


@app.post(
    "/admin/administradores",
    response_model=UsuarioRespuesta,
    status_code=201,
)
def crear_administrador(
    datos: UsuarioCrear,
    admin: Usuario = Depends(obtener_admin),
    db: Session = Depends(obtener_sesion),
):
    nuevo = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        tip_usu=1,
    )
    nuevo.perfil = Perfil()
    db.add(nuevo)

    try:
        db.commit()
        db.refresh(nuevo)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado")

    logger.info("Admin %s creó al administrador %s", admin.id_usr, nuevo.id_usr)

    return nuevo
