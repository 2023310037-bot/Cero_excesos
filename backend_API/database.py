import os

import pymysql
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, select, text
from sqlalchemy.engine import URL
from sqlalchemy.orm import sessionmaker, DeclarativeBase

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "cero_excesos")

url = URL.create(
    drivername="mysql+pymysql",
    username=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME,
    query={"charset": "utf8mb4"},
)

engine = create_engine(url, pool_pre_ping=True)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    pass


def obtener_sesion():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


CATEGORIAS_INICIALES = [
    "Finanzas",
    "Fitness & Salud",
    "Hábitos Estudiantiles",
    "Estilo de Vida",
]


def crear_base_si_no_existe():
    conexion = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
    )

    try:
        with conexion.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
        conexion.commit()
    finally:
        conexion.close()


def migrar_bd():
    columnas = [c["name"] for c in inspect(engine).get_columns("usuario")]

    if "activo" not in columnas:
        with engine.begin() as conexion:
            conexion.execute(
                text("ALTER TABLE usuario ADD COLUMN activo INT NOT NULL DEFAULT 1")
            )


def inicializar_bd():
    import models

    crear_base_si_no_existe()
    Base.metadata.create_all(bind=engine)
    migrar_bd()

    with SessionLocal() as db:
        existente = db.scalars(select(models.Categoria)).first()

        if existente is None:
            for nombre in CATEGORIAS_INICIALES:
                db.add(models.Categoria(nom_cat=nombre))

            db.commit()
