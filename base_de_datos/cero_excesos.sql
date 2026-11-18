-- Cero Excesos - Script de creación de la base de datos (MySQL / MariaDB)
-- Importar desde phpMyAdmin (pestaña "Importar") o ejecutar:
--     mysql -u root < base_de_datos/cero_excesos.sql   

CREATE DATABASE IF NOT EXISTS cero_excesos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cero_excesos;

-- Usuarios (tip_usu: 1 = administrador, 2 = usuario general)
CREATE TABLE IF NOT EXISTS usuario (
    id_usr     INT AUTO_INCREMENT PRIMARY KEY,
    nom_usr    VARCHAR(100) NOT NULL,
    mail       VARCHAR(150) NOT NULL UNIQUE,
    `pass`     VARCHAR(255) NOT NULL,          -- hash Argon2, nunca la contraseña
    tip_usu    INT NOT NULL DEFAULT 2,
    fecha_reg  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo     INT NOT NULL DEFAULT 1           -- 1 = activo, 0 = dado de baja
) ENGINE=InnoDB;

-- Perfil (relación 1 a 1 con usuario)
CREATE TABLE IF NOT EXISTS perfil (
    id_perfil  INT AUTO_INCREMENT PRIMARY KEY,
    usr_id     INT NOT NULL UNIQUE,
    biografia  VARCHAR(300) NULL,
    foto       VARCHAR(500) NULL,
    CONSTRAINT fk_perfil_usuario FOREIGN KEY (usr_id) REFERENCES usuario (id_usr)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS categoria (
    id_cat   INT AUTO_INCREMENT PRIMARY KEY,
    nom_cat  VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Entradas del blog
CREATE TABLE IF NOT EXISTS blog (
    id_blog    INT AUTO_INCREMENT PRIMARY KEY,
    titulo     VARCHAR(150) NOT NULL,
    contenido  TEXT NOT NULL,
    img        VARCHAR(500) NULL,
    fecha      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_id     INT NOT NULL,
    cat_id     INT NOT NULL,
    CONSTRAINT fk_blog_usuario   FOREIGN KEY (usr_id) REFERENCES usuario (id_usr),
    CONSTRAINT fk_blog_categoria FOREIGN KEY (cat_id) REFERENCES categoria (id_cat)
) ENGINE=InnoDB;

-- Comentarios
CREATE TABLE IF NOT EXISTS comentarios (
    id_com      INT AUTO_INCREMENT PRIMARY KEY,
    comentario  TEXT NOT NULL,
    fecha       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus     INT NOT NULL DEFAULT 1,
    usr_id      INT NOT NULL,
    blog_id     INT NOT NULL,
    CONSTRAINT fk_com_usuario FOREIGN KEY (usr_id)  REFERENCES usuario (id_usr),
    CONSTRAINT fk_com_blog    FOREIGN KEY (blog_id) REFERENCES blog (id_blog)
) ENGINE=InnoDB;

-- Valoración con estrellas (1 a 5). Una valoración por usuario y entrada.
CREATE TABLE IF NOT EXISTS valoracion (
    id_val   INT AUTO_INCREMENT PRIMARY KEY,
    puntos   INT NOT NULL,
    fecha    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_id   INT NOT NULL,
    blog_id  INT NOT NULL,
    CONSTRAINT uq_valoracion_blog_usr UNIQUE (blog_id, usr_id),
    CONSTRAINT fk_val_usuario FOREIGN KEY (usr_id)  REFERENCES usuario (id_usr),
    CONSTRAINT fk_val_blog    FOREIGN KEY (blog_id) REFERENCES blog (id_blog)
) ENGINE=InnoDB;

-- Reacciones a comentarios (me_gusta, me_encanta, risa, asombro, tristeza, fuego)
CREATE TABLE IF NOT EXISTS reaccion_comentario (
    id_rea  INT AUTO_INCREMENT PRIMARY KEY,
    tipo    VARCHAR(20) NOT NULL,
    fecha   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_id  INT NOT NULL,
    com_id  INT NOT NULL,
    CONSTRAINT uq_reaccion_com_usr_tipo UNIQUE (com_id, usr_id, tipo),
    CONSTRAINT fk_rea_usuario    FOREIGN KEY (usr_id) REFERENCES usuario (id_usr),
    CONSTRAINT fk_rea_comentario FOREIGN KEY (com_id) REFERENCES comentarios (id_com)
) ENGINE=InnoDB;

-- Categorías iniciales
INSERT IGNORE INTO categoria (id_cat, nom_cat) VALUES
    (1, 'Finanzas'),
    (2, 'Fitness & Salud'),
    (3, 'Hábitos Estudiantiles'),
    (4, 'Estilo de Vida');
