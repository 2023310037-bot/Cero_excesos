# Cero Excesos

Blog de estilo de vida universitario: finanzas, hábitos estudiantiles, fitness y bienestar.
Proyecto de la materia **Análisis y diseño de software** (LITIID013) · UTEQ.

**Autores:** Luis Manuel Juárez Pérez · Gerardo Esquivel Monterde

La app (Flutter) y la API (FastAPI) comparten una misma base de datos MySQL, por lo que funciona en web (Chrome) y en móvil con el mismo código.

---

## Qué puedes hacer

**Cualquier visitante**
- Leer las entradas del blog (las más recientes primero) y filtrarlas por categoría.
- Buscar entradas y ver el detalle con su promedio de estrellas y sus comentarios.

**Usuario registrado**
- Crear cuenta e iniciar sesión.
- Publicar, editar y eliminar **sus** entradas (con foto desde la galería) y ver "Mis entradas".
- Comentar, reaccionar a comentarios con emojis y enviar stickers.
- Calificar entradas de 1 a 5 estrellas (una vez por entrada).
- Editar su perfil (biografía y foto) y cambiar su correo o su contraseña.

**Administrador**
- Todo lo anterior, más:
- Ver la lista de usuarios, buscarlos, **darlos de baja o de alta**.
- Convertir a un usuario en administrador o quitarle el rol, y **crear nuevos administradores**.
- Eliminar cualquier comentario inapropiado y cualquier entrada.

Las categorías son: Finanzas, Fitness & Salud, Hábitos Estudiantiles y Estilo de Vida.

---

## Tecnologías

| Parte | Tecnología |
|---|---|
| App | Flutter (Dart), `http`, `image_picker` |
| API | Python, FastAPI, SQLAlchemy, Uvicorn |
| Base de datos | MySQL / MariaDB (XAMPP) |
| Seguridad | Hash Argon2 (pwdlib), tokens JWT (PyJWT) |

---

## Estructura del proyecto

```
Cero_Excesos/
├── base_de_datos/
│   └── cero_excesos.sql        Script SQL de la base de datos
├── backend_API/
│   ├── main.py                 Rutas de la API
│   ├── models.py               Tablas (SQLAlchemy)
│   ├── schemas.py              Validación de datos (Pydantic)
│   ├── database.py             Conexión y creación automática de la BD
│   ├── datos_demo.py           Usuarios y entradas de ejemplo
│   ├── requirements.txt        Librerías de Python
│   ├── .env.example            Plantilla de configuración
│   └── uploads/                Fotos subidas (se generan al usar la app)
└── flutter_cero_excesos/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart           Tema y rutas
        ├── models/             Clases de datos
        ├── services/           Comunicación con la API
        ├── screens/            Pantallas
        └── widgets/            Componentes reutilizables
```

---

## Requisitos previos

- [Python 3.10 o superior](https://www.python.org/downloads/) (marca "Add Python to PATH" al instalar)
- [XAMPP](https://www.apachefriends.org/) con **MySQL** (o cualquier MySQL/MariaDB)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) y Google Chrome
- [Visual Studio Code](https://code.visualstudio.com/) (recomendado) con las extensiones de Dart y Flutter

---

## Instalación y ejecución (Windows)

### 1. Descargar el proyecto

```powershell
git clone https://github.com/2023310037-bot/Cero_excesos.git
cd Cero_excesos
```

También puedes usar **Code → Download ZIP** en GitHub y descomprimirlo.

### 2. Encender MySQL

Abre XAMPP y presiona **Start** en **MySQL**. No necesitas crear la base de datos a mano: la API la crea sola.

### 3. Configurar y levantar la API

```powershell
cd backend_API
python -m venv venv
copy .env.example .env
venv\Scripts\python.exe -m pip install -r requirements.txt
venv\Scripts\python.exe datos_demo.py
venv\Scripts\python.exe -m uvicorn main:app --reload
```

- En `.env` ajusta `DB_PASSWORD` si tu MySQL tiene contraseña para `root` (en XAMPP suele estar vacía).
- En `.env` cambia `JWT_SECRET_KEY` por una clave larga y secreta. Puedes generar una con:
  `venv\Scripts\python.exe -c "import secrets; print(secrets.token_hex(32))"`
- `datos_demo.py` es opcional: crea usuarios y entradas de ejemplo.
- Si ves `Application startup complete.`, la API funciona. Déjala abierta.
- Documentación interactiva de la API: <http://127.0.0.1:8000/docs>

Si prefieres crear la base manualmente, importa `base_de_datos/cero_excesos.sql` en phpMyAdmin.

> Si PowerShell bloquea la activación del entorno virtual, no la necesitas: los comandos de arriba usan `venv\Scripts\python.exe` directamente.

### 4. Ejecutar la app Flutter

En **otra terminal**:

```powershell
cd flutter_cero_excesos
flutter create --project-name flutter_cero_excesos .
flutter pub get
```

Después:

1. Elimina el archivo `test/widget_test.dart` (lo vuelve a crear `flutter create` y no aplica a esta app).
2. Abre `lib/services/api_config.dart` y confirma la dirección del servidor en `baseUrl`:

| Dónde corres la app | Valor de `baseUrl` |
|---|---|
| Chrome o Windows | `http://127.0.0.1:8000` |
| Emulador de Android | `http://10.0.2.2:8000` |
| Celular físico (misma red WiFi) | `http://IP_DE_TU_PC:8000` (inicia la API con `--host 0.0.0.0`) |

3. Ejecuta:

```powershell
flutter run -d chrome
```

---

## Usuarios de prueba

Se crean al ejecutar `datos_demo.py`:

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | `admin@ceroexcesos.mx` | `Admin12345` |
| Usuario | `demo@ceroexcesos.mx` | `Demo12345` |

Son solo para pruebas locales.

---

## Principales rutas de la API

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/usuarios` | Registro |
| POST | `/login` | Inicio de sesión (devuelve el token) |
| GET / PUT | `/perfil/me` | Ver y editar mi perfil |
| PUT | `/perfil/me/correo`, `/perfil/me/password` | Cambiar correo o contraseña |
| GET | `/categorias` | Lista de categorías |
| GET / POST | `/blog` | Listar y crear entradas |
| GET / PUT / DELETE | `/blog/{id}` | Ver, editar y eliminar una entrada |
| GET / POST | `/blog/{id}/comentarios`, `/comentarios` | Comentarios |
| DELETE | `/comentarios/{id}` | Eliminar comentario (autor o admin) |
| POST | `/comentarios/{id}/reaccion` | Reaccionar a un comentario |
| GET / POST | `/blog/{id}/valoracion` | Ver y enviar calificación |
| GET | `/admin/usuarios` | Lista de usuarios (admin) |
| PUT | `/admin/usuarios/{id}/estado` | Dar de baja o de alta (admin) |
| PUT | `/admin/usuarios/{id}/rol` | Cambiar rol (admin) |
| POST | `/admin/administradores` | Crear administrador (admin) |

---

## Seguridad

- Las contraseñas se guardan como **hash Argon2**, nunca en texto plano.
- Las sesiones usan **tokens JWT** firmados que expiran a las 2 horas.
- Las rutas de administración exigen rol de administrador, y un administrador no puede darse de baja a sí mismo.
- Los usuarios dados de baja pierden el acceso aunque tengan una sesión abierta.
- Los cambios de correo y contraseña piden la contraseña actual.
- Solo se aceptan imágenes JPG, PNG o WEBP de hasta 5 MB, guardadas con nombre aleatorio.
- El archivo `.env` (claves y contraseñas) **no se sube al repositorio**.
- Los errores inesperados se registran en `backend_API/logs/errores.log`.

---

## Problemas frecuentes

| Problema | Solución |
|---|---|
| `Connection refused` / error 2003 al iniciar | MySQL no está encendido: inicia MySQL en XAMPP. |
| `No hay conexión con el servidor` en la app | La API no está corriendo o `baseUrl` en `api_config.dart` no coincide con tu caso. |
| `No module named ...` | Instala las librerías: `venv\Scripts\python.exe -m pip install -r requirements.txt`. |
| Cientos de errores rojos en VS Code | Falta ejecutar `flutter pub get` dentro de `flutter_cero_excesos`. |
| `Unknown column ...` | Existe una base `cero_excesos` antigua con otra estructura: elimínala en phpMyAdmin y vuelve a ejecutar `datos_demo.py`. |
| Error en `test/widget_test.dart` | Borra ese archivo. |

---

## Licencia

Proyecto académico con fines educativos.