# Cero Excesos

Blog de estilo de vida universitario (finanzas, hábitos y fitness).
*Análisis y diseño de software* · LITIID013 · UTEQ.

Misma estructura que `Flutter_LITIID013`: **FastAPI + MySQL (XAMPP)** y **Flutter** con las carpetas
`models / screens / services / widgets`.

```
Cero_Excesos/
├── base_de_datos/
│   └── cero_excesos.sql          Script de creación de la base de datos MySQL
├── backend_API/                  FastAPI (igual que tu proyecto)
│   ├── .env.example              Plantilla: cópiala como .env (el .env no se sube a GitHub)
│   ├── database.py               Conexión SQLAlchemy + creación automática de BD y categorías
│   ├── models.py                 Usuario, Perfil, Categoria, Blog, Comentario
│   ├── schemas.py                Esquemas Pydantic
│   ├── main.py                   Rutas de la API
│   ├── datos_demo.py             Usuarios y entradas de ejemplo (opcional)
│   ├── requirements.txt
│   └── uploads/                  Fotos de entradas y perfiles
└── flutter_cero_excesos/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart             Rutas con nombre (/login, /register, /blog, /add-blog, /profile)
        ├── models/               user, post, comentario, categoria, valoracion, reaccion
        ├── services/             api_config, auth, post, comentario, categoria, user, valoracion
        ├── screens/              login, register, blog, post_detail, add_blog, profile
        └── widgets/              auth_background, auth_card, custom_text_field, primary_button,
                                  category_chip, post_card, user_drawer, app_colores,
                                  star_rating, reaction_bar, sticker_picker,
                                  dialogo_cambiar_correo, dialogo_cambiar_password
```

## 1. Backend

1. Enciende **MySQL** en XAMPP y copia `backend_API/.env.example` como `backend_API/.env` (ajusta usuario, contraseña y `JWT_SECRET_KEY`).
2. En la terminal de VS Code:

```bash
cd backend_API
python -m venv venv
venv\Scripts\activate             # Linux/Mac: source venv/bin/activate
pip install -r requirements.txt
python datos_demo.py              # opcional: usuarios y 4 entradas de ejemplo
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

La base `cero_excesos`, las tablas y las 4 categorías se crean solas al arrancar.
También puedes crearlas a mano importando `base_de_datos/cero_excesos.sql` en phpMyAdmin (es el mismo modelo).
Documentación de la API: <http://127.0.0.1:8000/docs>

Usuarios demo (`datos_demo.py`): `demo@ceroexcesos.mx` / `Demo12345` y administrador `admin@ceroexcesos.mx` / `Admin12345`.

## 2. App Flutter (móvil y web)

**Opción A — dentro de tu proyecto actual** (ya tiene las carpetas `android/`, `ios/`…):
copia `lib/` y `pubspec.yaml` de `flutter_cero_excesos` sobre tu proyecto y ejecuta `flutter pub get`.

**Opción B — proyecto nuevo:**

```bash
cd flutter_cero_excesos
flutter create --project-name flutter_cero_excesos .
flutter pub get
```

Antes de correr, pon la dirección de tu servidor en **un solo lugar**: `lib/services/api_config.dart`
(celular físico = IP de tu PC, emulador Android = `10.0.2.2`, Chrome = `127.0.0.1`).

```bash
flutter run                 # celular o emulador
flutter run -d chrome       # versión web (mismo código, mismo servidor y BD)
```

La versión web del RF000 se obtiene con `flutter run -d chrome` / `flutter build web`.
Si la app es Android y usas `http://`, tu proyecto actual ya debe permitirlo
(`android:usesCleartextTraffic="true"`); en un proyecto nuevo hay que agregarlo en `AndroidManifest.xml`.

## 3. Requerimientos → dónde están

| Requerimiento | API (`main.py`) | Flutter |
|---|---|---|
| RF001 Registro | `POST /usuarios` | `register_user_page.dart`, `auth_service.dart` |
| RF002 Inicio de sesión (mensaje si falla) | `POST /login` | `login_user_page.dart`, `auth_service.dart` |
| RF003 Publicar y gestionar entradas | `POST/PUT/DELETE /blog` | `add_blog_page.dart`, `post_service.dart` |
| RF004 Consultar publicaciones (recientes primero) | `GET /blog`, `GET /blog/{id}` | `blog_page.dart`, `post_detail_page.dart` |
| RF005 Categorías | `GET /categorias`, `GET /blog?cat_id=` | `category_chip.dart`, `blog_page.dart` |
| RF006 Comentarios (con sesión, no vacíos) | `GET /blog/{id}/comentarios`, `POST /comentarios` | `post_detail_page.dart`, `comentario_service.dart` |
| RF007 Perfil (solo el de la sesión) | `GET/PUT /perfil/me` | `profile_page.dart`, `user_service.dart` |
| Extra: cambiar correo y contraseña (piden la contraseña actual) | `PUT /perfil/me/correo`, `PUT /perfil/me/password` | `dialogo_cambiar_correo.dart`, `dialogo_cambiar_password.dart` |
| Extra: valoración con estrellas (1 a 5, una por usuario) | `GET/POST /blog/{id}/valoracion` | `star_rating.dart`, `post_detail_page.dart`, `valoracion_service.dart` |
| Extra: comentarios interactivos (reacciones y stickers) | `POST /comentarios/{id}/reaccion` | `reaction_bar.dart`, `sticker_picker.dart`, `post_detail_page.dart` |
| Extra: "Mis entradas" | `GET /blog?usr_id=` | `blog_page.dart` |
| Extra: administrar usuarios (listar, dar de baja/alta, cambiar rol) | `GET /admin/usuarios`, `PUT /admin/usuarios/{id}/estado`, `PUT /admin/usuarios/{id}/rol` | `admin_users_page.dart`, `admin_service.dart` |
| Extra: crear administradores | `POST /admin/administradores` | `admin_users_page.dart` |
| Extra: moderar comentarios (el administrador o el autor eliminan) | `DELETE /comentarios/{id}` | `post_detail_page.dart`, `comentario_service.dart` |
| RNF-001/002 Diseño y contraste | — | `app_colores.dart` + widgets |
| RNF-003 API REST | todas las rutas (JSON) | carpeta `services/` |
| RNF-004 Registro de errores | `logs/errores.log` + manejadores de error | `ApiConfig.mensajeError` |

## 4. Qué cambió respecto a tu proyecto de referencia

- Se agregó la tabla `categoria` (el diagrama de clases la pide) y `perfil` (biografía y foto).
- Los comentarios usan el usuario del **token**, no un `usr_id` enviado por la app (así nadie comenta a nombre de otro) y la API devuelve el nombre del autor.
- La dirección del servidor está en `api_config.dart` (antes estaba repetida en cada servicio con IPs distintas).
- Se leen las respuestas con UTF-8 para que las tildes de los mensajes se vean bien.
- Leer el blog no requiere cuenta (RF004); escribir y comentar sí.
- El rol de administrador (`tip_usu = 1`) puede eliminar entradas y comentarios, ver la lista de usuarios, darlos de baja o de alta, y crear otros administradores. Un usuario dado de baja no puede iniciar sesión.
- La subida de fotos usa solo la galería (se quitó la cámara).
- Diseño minimalista centralizado en el tema de `main.dart`.

## 5. Seguridad (para el reporte)

- **Contraseñas:** se guardan como hash Argon2 (pwdlib), nunca en texto plano. Es un hash de un solo sentido, más seguro que una encriptación reversible.
- **Sesiones:** token JWT firmado con `JWT_SECRET_KEY`, que expira a las 2 horas y se manda en el encabezado `Authorization: Bearer`.
- **Control de acceso:** solo el autor edita su entrada; el autor o el administrador la eliminan; nadie valora su propia entrada; el autor de un comentario o reacción sale del token, no de la petición.
- **Cambio de correo y contraseña:** exigen la contraseña actual.
- **Administración:** las rutas `/admin/*` exigen rol administrador; un administrador no puede darse de baja ni cambiarse el rol a sí mismo. Las bajas se verifican en cada petición, no solo al iniciar sesión.
- **Manejo de errores:** respuestas con mensajes claros y registro de errores inesperados en `backend_API/logs/errores.log`.
- **Archivos:** solo JPG, PNG y WEBP de hasta 5 MB, con nombre aleatorio.
