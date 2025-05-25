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
    alias VARCHAR(100) UNIQUE,
    nombre VARCHAR(100) NOT NULL UNIQUE,
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

	idFruta INT IDENTITY PRIMARY KEY,
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

--TRIGERS

CREATE TABLE LOG_RECOMPENSAS (
    id_log INT IDENTITY PRIMARY KEY,
    id_personaje INT,
    antigua_recompensa DECIMAL(15,2),
    nueva_recompensa DECIMAL(15,2),
    fecha_cambio DATETIME DEFAULT GETDATE()
);

GO

CREATE OR ALTER TRIGGER Log_Recompensa
ON PERSONAJE AFTER UPDATE
AS
BEGIN

	DECLARE @recompensaAntes DECIMAL (15,2) = (SELECT deleted.recompensa FROM deleted)
	DECLARE @recompensaDespues DECIMAL (15,2) = (SELECT inserted.recompensa FROM inserted)

    IF ((@recompensaAntes != @recompensaDespues) OR (@recompensaDespues IS NOT NULL))
    BEGIN
        INSERT INTO LOG_RECOMPENSAS (id_personaje, antigua_recompensa, nueva_recompensa)
        SELECT d.idPersonaje, d.recompensa, i.recompensa
        FROM deleted d
        JOIN inserted i ON d.idPersonaje = i.idPersonaje
        WHERE d.recompensa != i.recompensa;
    END
END; --Log para cada vez que se actualice el bounty (recompensa) se agrege a la tabla de logs.

GO

CREATE OR ALTER TRIGGER TR_Delete_Conflictos_Banda
ON BANDA_PIRATA INSTEAD OF DELETE
AS
BEGIN

	DECLARE @idBanda as INT = (SELECT deleted.idBanda FROM deleted)
	DECLARE @idCapitan as INT = (SELECT deleted.capitan FROM deleted)

    DELETE FROM BANDA_ENEMIGA
    WHERE id_banda_1 IN (SELECT idBanda FROM deleted)
       OR id_banda_2 IN (SELECT idBanda FROM deleted)
       OR ganador_id IN (SELECT idBanda FROM deleted);

	UPDATE PIRATA SET
	id_banda = null
	WHERE id_banda = @idBanda

	UPDATE PERSONAJE SET
	esta_vivo = 0
	WHERE idPersonaje = @idCapitan

	UPDATE FRUTA_DEL_DIABLO SET
	disponibilidad = 1
	WHERE id_personaje = @idCapitan

	DELETE FROM BANDA_PIRATA
	WHERE idBanda = @idBanda

	DELETE FROM HAKI_PERSONAJE
	WHERE id_personaje = @idCapitan
END; -- Trigger para borrar relaciones cuando una Banda es eliminada/borrada.

GO

CREATE OR ALTER TRIGGER AsociarBandaACapitanes
ON BANDA_PIRATA AFTER INSERT
AS
BEGIN

	DECLARE @idPirata as INT = (SELECT inserted.capitan FROM inserted)
	DECLARE @idBanda as INT = (SELECT inserted.idBanda FROM inserted)
	
	UPDATE PIRATA SET
	id_banda = @idBanda
	WHERE id_personaje = @idPirata;

	UPDATE BANDA_PIRATA SET
	numero_integrantes = (SELECT COUNT(*) FROM PIRATA WHERE id_banda = @idBanda)
	WHERE idBanda = @idBanda;
    
END; --Cuando creamos un pirata y es el capitan. La banda esta en null, porque aun no existe. Al crear la banda asignamos en Pirata la banada al capitan de esta misma. 

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
('Hachinosu', 'Tropical', 'Marshall D. Teach', 'Yonko', 3),
('Shimotsuki Village', 'Templado', 'Kosaburo Shimotsuki', 'Neutral', 1);

GO

INSERT INTO HAKI (nombreHaki, descripcion) VALUES
('Observacion', 'Permite percibir la presencia y emociones del oponente'),
('Armadura', 'Endurece el cuerpo para proteger y atacar'),
('Conquistador', 'Domina la voluntad de los más débiles');

GO

INSERT INTO PERSONAJE (alias, nombre, recompensa, esta_vivo, edad, genero, tipo_personaje, id_region) VALUES 
('Sombrero de paja', 'Monkey D. Luffy', 3000000000.00, 1, 19, 'masculino', 'pirata', 1),
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
('Sombrero de Paja', 0, 10, 1);

INSERT INTO BANDA_PIRATA (nombre, yonko, numero_integrantes, capitan) VALUES 
('Heart Pirates', 0, 8, 4);

INSERT INTO BANDA_PIRATA (nombre, yonko, numero_integrantes, capitan) VALUES 
('Kid Pirates', 0, 15, 5);

INSERT INTO BANDA_PIRATA (nombre, yonko, numero_integrantes, capitan) VALUES 
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

GO

--Advanced SELECT Queries.

--JOIN

SELECT P.nombre, P.recompensa, BP.nombre ,(SELECT P.nombre WHERE BP.capitan = P.idPersonaje) as 'capitan', M.nombreMar
FROM PERSONAJE P
JOIN PIRATA PT on PT.id_personaje = P.idPersonaje
JOIN BANDA_PIRATA BP on BP.idBanda = PT.id_banda
JOIN REGION R on R.idRegion = P.id_region
JOIN MAR M on M.idMar = R.id_Mar
ORDER BY P.recompensa;--Esta Querry sirve para ver informacion detallada de todos los piratas que tenemos registrados en el sistema.

--SUBQUERRY

SELECT P.idPersonaje, P.nombre, M.nombreMar, P.recompensa
FROM PERSONAJE P
JOIN REGION R on R.idRegion = P.id_region
JOIN MAR M on M.idMar = R.id_Mar
WHERE P.recompensa = (SELECT MAX(P2.recompensa) FROM PERSONAJE P2
						JOIN REGION R2 ON R2.idRegion = P2.id_region
						WHERE R2.id_Mar = M.idMar);

--Nos muestra la mayor recompensa por mar y a quien le corresponde. Si coinciden varios Personajes se imprimen todos. 

--GROUP BY

SELECT P.tipo_personaje,COUNT(*) as CANTIDAD
FROM PERSONAJE P
WHERE P.esta_vivo = 1
GROUP BY P.tipo_personaje;

-- ORDER BY, DISTINCT

SELECT DISTINCT(FD.idFruta), P.nombre, P.recompensa, FD.nombre, FD.tipo
FROM PERSONAJE P
JOIN FRUTA_DEL_DIABLO FD on FD.id_personaje = P.idPersonaje
WHERE P.idPersonaje IN (SELECT FD2.id_personaje FROM FRUTA_DEL_DIABLO FD2 WHERE FD2.disponibilidad = 0)
ORDER BY FD.tipo,P.recompensa desc;
--Lista todos los personajes con fruta del diablo, ordenados por tipo de fruta y recompensa descendente, sin repetir frutas.


--COMPLEX FILTER

SELECT BP.nombre
FROM BANDA_PIRATA BP
JOIN BANDA_ENEMIGA BE on BE.id_banda_1 = BP.idBanda OR BE.id_banda_2 = BP.idBanda
WHERE BE.nivel_hostilidad > (SELECT AVG(nivel_hostilidad)
							FROM BANDA_ENEMIGA);

--Muestra todas las bandas enemigas cuyo nivel de hostilidad es mayor al promedio general de todos los conflictos.

--PROCEDIMIENTOS
GO

CREATE OR ALTER PROCEDURE InsertarOActualizarPirata 
(@alias VARCHAR(100), 
@nombre VARCHAR(100), 
@recompensa DECIMAL(15,2), 
@edad INT, 
@genero VARCHAR(20), 
@region INT, 
@objetivo TEXT, 
@afiliado_a_yonko BIT,
@bandaPirata as INT)
AS
BEGIN

	DECLARE @idPersonaje as INT;

	SELECT @idPersonaje = (SELECT idPersonaje FROM PERSONAJE WHERE alias = @alias OR nombre = @nombre)
	
	IF @idPersonaje IS NOT NULL
	BEGIN

		UPDATE PERSONAJE SET 
        nombre = @nombre,
		alias = @alias,
        recompensa = @recompensa,
        edad = @edad,
        genero = @genero,
        id_region = @region
        WHERE idPersonaje = @idPersonaje;

        UPDATE PIRATA SET 
        objetivo_principal = @objetivo,
        afiliado_a_yonko = @afiliado_a_yonko
        WHERE id_personaje = @idPersonaje;

	END
	ELSE
	BEGIN

		INSERT INTO PERSONAJE (alias, nombre, recompensa, esta_vivo, edad, genero, tipo_personaje, id_region) VALUES 
		(@alias, @nombre, @recompensa, 1, @edad, @genero, 'pirata', @region);

        SET @idPersonaje = SCOPE_IDENTITY(); -- Recuperamos el ID recién generado

        INSERT INTO PIRATA (id_personaje, objetivo_principal, afiliado_a_yonko, id_banda) VALUES 
		(@idPersonaje, @objetivo, @afiliado_a_yonko, @bandaPirata);

	END
END; --Este procedimiento inserta un nuevo pirata (si no exite tambien genera un Personaje) o actualiza sus datos si ya existe. 

GO

EXEC InsertarOActualizarPirata 'El Cazador de Piratas','Roronoa Zoro',1111000010.00,21,'masculino',6,'Convertirse en el mejor espadachín del mundo',1,1;

GO

EXEC InsertarOActualizarPirata 'El rey del Inframundo','Roronoa Zoro',1111000000.00,21,'masculino',6,'Convertirse en el mejor espadachín del mundo',1,1;

GO

CREATE OR ALTER PROCEDURE ObtenerPersonajesConFiltro
	
	(@nombreMar VARCHAR(100),
	@tipo_personaje VARCHAR(10),
    @tiene_fruta BIT)
	
AS
BEGIN

	SELECT P.idPersonaje, P.nombre, P.tipo_personaje, M.nombreMar, FD.nombre AS fruta
    FROM PERSONAJE P
    JOIN REGION R ON P.id_region = R.idRegion
    JOIN MAR M ON R.id_Mar = M.idMar
    LEFT JOIN FRUTA_DEL_DIABLO FD ON P.idPersonaje = FD.id_personaje
    WHERE 
        (M.nombreMar = @nombreMar)
        AND (P.tipo_personaje = @tipo_personaje)
        AND ( 
            (@tiene_fruta = 1 AND FD.idFruta IS NOT NULL) OR 
            (@tiene_fruta = 0 AND FD.idFruta IS NULL));

END;--Filtro especifico segun mar,tipo de Personaje y si tiene fruta o no.

GO

EXEC ObtenerPersonajesConFiltro 'East Blue','pirata',1;

GO

EXEC ObtenerPersonajesConFiltro 'East Blue','pirata',0;
