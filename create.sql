-- TABLE Utilisateurs
CREATE TYPE UserType AS ENUM ('organisation', 'individu', 'application');

CREATE TABLE Utilisateurs (
	login VARCHAR(30) PRIMARY KEY,
	mdp VARCHAR(50),
	type UserType
);

-- TABLE Formulaire
CREATE TABLE Formulaire (
	id INTEGER PRIMARY KEY,
	createur VARCHAR(30) REFERENCES Utilisateurs(login) NOT NULL,
	destructeur VARCHAR(30) REFERENCES Utilisateurs(login),
	nom VARCHAR(30),
	date_creation DATE NOT NULL,
	date_suppression DATE
);
-- trigger sur les dates
CREATE OR REPLACE FUNCTION form_trig_date() RETURNS TRIGGER AS
'
BEGIN
	IF NEW.date_creation > NEW.date_suppression THEN
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
'
LANGUAGE 'plpgsql';

CREATE TRIGGER form_trigger_date
BEFORE INSERT OR UPDATE ON Formulaire
FOR EACH ROW
WHEN (NEW.date_creation IS NOT NULL AND NEW.date_suppression IS NOT NULL)
EXECUTE PROCEDURE form_trig_date();

-- Contraintes de projection: Vues devant retourner NULL normalement 
CREATE VIEW form_createur(login) AS
SELECT DISTINCT createur
FROM Formulaire
EXCEPT
SELECT login
FROM Utilisateurs;

CREATE VIEW form_destructeur(login) AS
SELECT DISTINCT destructeur
FROM Formulaire
EXCEPT
SELECT login
FROM Utilisateurs;
 
-- TABLE Champ
CREATE TABLE Champ (
	form INTEGER REFERENCES Formulaire(id),
	id INTEGER,
	type varchar(30),
	actif boolean,
	obligatoire boolean,
	version serial,
	date_creation Date NOT NULL,
	date_suppression Date,
	createur VARCHAR(30) REFERENCES Utilisateurs(login) NOT NULL,
	destructeur VARCHAR(30) REFERENCES Utilisateurs(login),
	PRIMARY KEY (form, id)
);

-- trigger sur les dates
CREATE TRIGGER champ_trigger_date
BEFORE INSERT OR UPDATE ON Formulaire
FOR EACH ROW
WHEN (NEW.date_creation IS NOT NULL AND NEW.date_suppression IS NOT NULL)
EXECUTE PROCEDURE form_trig_date();

-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW champ_createur(login) AS
SELECT DISTINCT createur
FROM Champ
EXCEPT
SELECT login
FROM Utilisateurs;

CREATE VIEW champ_destructeur(login) AS
SELECT DISTINCT destructeur
FROM Champ
EXCEPT
SELECT login
FROM Utilisateurs;

--TABLE Label
CREATE TABLE Label (
	id integer PRIMARY KEY,
	champ INTEGER NOT NULL,
	champ_form INTEGER NOT NULL,
	valeur varchar(30),
	langue varchar(30),
	FOREIGN KEY(champ, champ_form) REFERENCES champ(id, form)
);
-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW label_champ_form(champ, form) AS
SELECT DISTINCT champ, champ_form
FROM Label
EXCEPT
SELECT id, form
FROM Champ;

-- TABLE Privilege
CREATE TABLE Privilege (
	login VARCHAR(30) REFERENCES Utilisateurs(login),
	form INTEGER REFERENCES Formulaire(id),
	code varchar(20) CHECK (code IN ('creationform','suppressionform', 'ajout', 'edition', 'suppression', 'activation')),
	PRIMARY KEY(login, form, code)
);
-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW privilege_login(login) AS
SELECT DISTINCT login
FROM Privilege
EXCEPT
SELECT login
FROM Utilisateurs;

CREATE VIEW privilege_form(form) AS
SELECT DISTINCT id
FROM Formulaire
EXCEPT
SELECT form
FROM Privilege;

-- TABLE Reponse
CREATE TABLE Reponse (
	id integer PRIMARY KEY,
	utilisateur VARCHAR(30) NOT NULL REFERENCES Utilisateurs(login),
	date Date
);
-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW reponse_user(utilisateur) AS
SELECT DISTINCT utilisateur
FROM Reponse
EXCEPT
SELECT login
FROM Utilisateurs;

-- TABLE Donnees
CREATE TABLE Donnees (
	rep INTEGER REFERENCES Reponse(id),
	id INTEGER,
	champ INTEGER NOT NULL,
	champ_form INTEGER NOT NULL, 
	contenu varchar(200),
	langue varchar(30),
	PRIMARY KEY(rep, id),
	FOREIGN KEY(champ, champ_form) REFERENCES Champ(id, form)
);
-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW donnees_rep(reponse) AS
SELECT DISTINCT id
FROM Reponse
EXCEPT
SELECT DISTINCT rep
FROM Donnees;

CREATE VIEW donnees_champ(champ, form) AS
SELECT DISTINCT champ, champ_form
FROM Donnees
EXCEPT
SELECT DISTINCT id, form
FROM Champ;

-- TABLE Modification
CREATE TABLE Modification (
	login VARCHAR(30) REFERENCES Utilisateurs(login),
	champ INTEGER,
	champ_form INTEGER,
	date_modif Date,
	valeur_type VARCHAR(30),
	valeur_actif Boolean,
	valeur_obligatoire Boolean,
	PRIMARY KEY(login, champ, champ_form, date_modif),
	FOREIGN KEY(champ, champ_form) REFERENCES Champ(id, form)
);
-- Contraintes de projection: Vues devant retourner NULL normalement
CREATE VIEW modification_login(login) AS
SELECT DISTINCT login
FROM Modification
EXCEPT
SELECT DISTINCT login
FROM Utilisateurs;

CREATE VIEW modification_champ(champ, form) AS
SELECT DISTINCT champ, champ_form
FROM Modification
EXCEPT
SELECT DISTINCT id, form
FROM Champ;
 
