CREATE DATABASE ONE_PIECE

GO

USE [ONE_PIECE]

GO

CREATE TABLE MAR(

	idMar INT PRIMARY KEY IDENTITY,
	nombreMar VARCHAR(100) NOT NULL
);

GO

CREATE TABLE REGION(

	idRegion INT IDENTITY PRIMARY KEY,
	nombreRegion VARCHAR(100) NOT NULL,
	tipo_clima VARCHAR(50) NOT NULL,
	lider VARCHAR(100) NOT NULL,
	alianza_actual VARCHAR(100),
	id_Mar INT,

	FOREIGN KEY (id_Mar) REFERENCES MAR(idMar)

);

GO


CREATE TABLE HAKI(

	idHaki INT IDENTITY PRIMARY KEY,
	nombreHaki VARCHAR (12) CHECK (nombreHaki IN ('Observacion', 'Armadura', 'Conquistador')) NOT NULL UNIQUE,
	descripcion TEXT

);

GO

CREATE TABLE PERSONAJE(

	idPersonaje INT IDENTITY PRIMARY KEY,
    alias VARCHAR(100),
    nombre VARCHAR(100) NOT NULL,
    recompensa DECIMAL(15,2) CHECK (recompensa >= 0) NOT NULL,
    esta_vivo BIT DEFAULT 1, --1 significa que esta vivo, 0 que no lo esta preferia hacer un booleano pero no existe la definicion como tal.
    edad INT CHECK (edad >= 0) NOT NULL,
    genero VARCHAR(20) CHECK (genero IN ('masculino', 'femenino', 'otro')) NOT NULL,
    tipo_personaje VARCHAR(10) CHECK (tipo_personaje IN ('pirata', 'marina', 'civil')) NOT NULL,
    id_region INT NOT NULL,
    FOREIGN KEY (id_region) REFERENCES REGION(idRegion)

);

GO

CREATE TABLE FRUTA_DEL_DIABLO(

	id INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE, --No existen 2 frutas del diablo iguales (o eso esta escrito...).
    estado_despertar BIT DEFAULT 0, --0 significa que no esta despertada, 1 si.
    disponibilidad BIT DEFAULT 1, --1 significa que esta disponible , 0 que no.
    tipo VARCHAR(50) CHECK (tipo IN ('paramecia', 'logia', 'zoan')) NOT NULL,
    id_personaje INT UNIQUE, -- Solo se puede consumir una fruta a la vez (o eso esta escrito...).
    FOREIGN KEY (id_personaje) REFERENCES PERSONAJE(idPersonaje)

);

GO

CREATE TABLE HAKI_PERSONAJE(

	id_haki INT,
    id_personaje INT,
    nivel VARCHAR (8) CHECK (nivel IN ('Basico','Avanzado','Experto')) NOT NULL,
    PRIMARY KEY (id_haki, id_personaje),
    FOREIGN KEY (id_haki) REFERENCES HAKI(idHaki),
    FOREIGN KEY (id_personaje) REFERENCES PERSONAJE(idPersonaje)

);

GO

CREATE TABLE MARINA(

	id_personaje INT PRIMARY KEY,
    cuartel VARCHAR(100),
    rango VARCHAR(50) CHECK (rango IN ('Iniciado','Comandante','ViceAlmirantes','Almirantes','Almirante de Flota')) NOT NULL,
    FOREIGN KEY (id_personaje) REFERENCES PERSONAJE(idPersonaje)

);

GO

CREATE TABLE CIVIL(

	id_personaje INT PRIMARY KEY,
    profesion VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_personaje) REFERENCES PERSONAJE(idPersonaje)

);

GO

CREATE TABLE PIRATA(

	id_personaje INT PRIMARY KEY,
    objetivo_principal TEXT NOT NULL,
    afiliado_a_yonko BIT DEFAULT 0, --0 es que no esta afiliado a ningun yonko, 1 es que si.
    id_banda INT,
    FOREIGN KEY (id_personaje) REFERENCES PERSONAJE(idPersonaje),

);

GO

CREATE TABLE BANDA_PIRATA(

	idBanda INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    yonko BIT DEFAULT 0, --0 significa que no es un yonko (emperador del mar), 1 significa que si lo es.
    numero_integrantes INT CHECK (numero_integrantes >= 1) NOT NULL,
    capitan INT UNIQUE NOT NULL,
    FOREIGN KEY (capitan) REFERENCES PIRATA(id_personaje)

);

GO

ALTER TABLE PIRATA 
ADD CONSTRAINT fk_banda
FOREIGN KEY (id_banda) REFERENCES BANDA_PIRATA (idBanda);

GO

CREATE TABLE BANDA_ENEMIGA (
    id_banda_1 INT,
    id_banda_2 INT,
    motivo TEXT NOT NULL,
    fecha_conflicto DATE NOT NULL,
    nivel_hostilidad INT CHECK (nivel_hostilidad BETWEEN 1 AND 10) NOT NULL,
    batallas INT DEFAULT 0 CHECK (batallas >= 0) NOT NULL,
    activo BIT DEFAULT 1, --1 significa que el conflicto entre bandas sigue vigente, 0 significa que se ha acabado. 
    ganador_id INT,
    PRIMARY KEY (id_banda_1, id_banda_2),
    FOREIGN KEY (id_banda_1) REFERENCES BANDA_PIRATA(idBanda),
    FOREIGN KEY (id_banda_2) REFERENCES BANDA_PIRATA(idBanda),
    FOREIGN KEY (ganador_id) REFERENCES BANDA_PIRATA(idBanda),
    CHECK (id_banda_1 != id_banda_2)
);

GO

INSERT INTO MAR (nombreMar) VALUES
('East Blue'),
('Grand Line'),
('New World');

GO

INSERT INTO REGION (nombreRegion, tipo_clima, lider, alianza_actual, id_mar)
VALUES 
('Shell Town', 'Templado', 'Capitan Morgan', 'Gobierno Mundial', 1),
('Water 7', 'Húmedo', 'Alcalde Iceburg', 'Neutral', 2),
('Wano', 'Variable', 'Monosuke (Hijo de Oden-sama)', 'Aliados de Luffy', 3),
('South Blue', 'Frío', 'Desconocido', 'Neutral', 1),
('Hachinosu', 'Tropical', 'Marshall D. Teach', 'Yonko', 3);

GO

INSERT INTO HAKI (nombreHaki, descripcion) VALUES
('Observacion', 'Permite percibir la presencia y emociones del oponente'),
('Armadura', 'Endurece el cuerpo para proteger y atacar'),
('Conquistador', 'Domina la voluntad de los más débiles');

GO

INSERT INTO PERSONAJE (alias, nombre, recompensa, esta_vivo, edad, genero, tipo_personaje, id_region) VALUES 
('Sombrero de paja', 'Monkey D. Luffy', 3000000000.00, 1, 19, 'masculino', 'pirata', 3),
('Smoker', 'Smoker', 500000.00, 1, 38, 'masculino', 'marina', 1),
('Iceburg', 'Iceburg', 0.00, 1, 45, 'masculino', 'civil', 2),
('Law', 'Trafalgar D. Water Law', 3000000000.00, 1, 26, 'masculino', 'pirata', 3),
('Kid', 'Eustass Kid', 3000000000.00, 1, 23, 'masculino', 'pirata', 4),
('Barbanegra', 'Marshall D. Teach', 3960000000.00, 1, 40, 'masculino', 'pirata', 5);

GO

INSERT INTO PIRATA (id_personaje, objetivo_principal, afiliado_a_yonko) VALUES 
(1, 'Convertirse en el Rey de los Piratas', 0),
(4, 'Investigar el Siglo Vacío y salvar vidas', 0),
(5, 'Derrotar a Shanks y conseguir los Road Poneglyphs', 0),
(6, 'Reinar como el único Yonko y obtener el One Piece', 1);

GO

INSERT INTO BANDA_PIRATA (nombre, yonko, numero_integrantes, capitan) VALUES 
('Sombrero de Paja', 0, 10, 1),
('Heart Pirates', 0, 8, 4),
('Kid Pirates', 0, 15, 5),
('Blackbeard Pirates', 1, 20, 6);

GO

INSERT INTO MARINA (id_personaje, cuartel, rango)
VALUES (2, 'Cuartel G-5', 'ViceAlmirantes');

GO

INSERT INTO CIVIL (id_personaje, profesion)
VALUES (3, 'Constructor naval y alcalde de Water 7');

GO

INSERT INTO FRUTA_DEL_DIABLO (nombre, estado_despertar, disponibilidad, tipo, id_personaje)
VALUES 
('Gomu Gomu no',0,0,'Paramecia',1);

GO

DELETE FROM FRUTA_DEL_DIABLO
WHERE nombre = 'Gomu Gomu no' --Por la trama, nos damos cuenta de que esta fruta nunca existio. Sino que era otra fruta mas poderosa la que tenia el protagonista.

GO

INSERT INTO FRUTA_DEL_DIABLO (nombre, estado_despertar, disponibilidad, tipo, id_personaje)
VALUES
('Zoan Mitologica Modelo:Nika', 1, 0, 'zoan', 1),
('Moku Moku no Mi', 0, 0, 'logia', 2),
('Jiki Jiki no Mi', 1, 0, 'paramecia', 5),
('Yami Yami no Mi', 1, 0, 'logia', 6),
('Ope Ope no Mi',1,0,'paramecia',4);

GO

INSERT INTO HAKI_PERSONAJE (id_haki, id_personaje, nivel)
VALUES 
(1, 1, 'Avanzado'),
(2, 1, 'Avanzado'),
(3, 1, 'Basico'), 
(1, 2, 'Basico'),
(2, 2, 'Avanzado'),
(1, 5, 'Avanzado'),
(2, 5, 'Avanzado'),
(3, 5, 'Basico'),
(1, 6, 'Avanzado'),
(2, 6, 'Avanzado'),
(3, 6, 'Avanzado');

GO

INSERT INTO BANDA_ENEMIGA (id_banda_1, id_banda_2, motivo, fecha_conflicto, nivel_hostilidad, batallas, activo, ganador_id) VALUES
(1, 2, 'Rivalidad por el Road Poneglyph', '2024-07-01', 7, 3, 0, 1),
(2, 4, 'Enfrentamiento directo en busca de los Road Poneglyphs', '2024-04-10', 9, 3, 0, 4);

INSERT INTO BANDA_ENEMIGA (id_banda_1, id_banda_2, motivo, fecha_conflicto, nivel_hostilidad, batallas, activo) VALUES
(2, 3, 'Rivalidad entre Supernovas por llegar al One Piece primero', '2024-06-01', 6, 2, 1)

GO

UPDATE BANDA_PIRATA SET
yonko = 1
WHERE idBanda = (SELECT idBanda FROM BANDA_PIRATA WHERE capitan = (SELECT idPersonaje FROM PERSONAJE WHERE nombre = 'Monkey D. Luffy'))
--Hacemos este UPDATE debido a que, por los ultimos acondecimientos de la serie. Actualmente Luffy es un emperador del MAR.


--Advanced SELECT Queries.

