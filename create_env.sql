/*
La shell andrà dunque ad eseguire uno file SQL via sqlplus,
 comune a tutti e tre i metodi che si occupera' di creare 
 l'utente, garantirgli i permessi necessari,
creare le directories, le tabelle e le eventuali 
funzioni/procedure necessarie per il controllo dei 
dati (CREATE_ENV.sql).
-
*/
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT 9

DROP USER carica CASCADE;

CREATE USER carica IDENTIFIED by carica;
GRANT connect, resource, dba to carica;

-- creo directory
CREATE OR REPLACE DIRECTORY data_dir AS 'c:\esercizioAgostino\data';
CREATE OR REPLACE DIRECTORY log_dir AS 'c:\esercizioAgostino\log';
CREATE OR REPLACE DIRECTORY bad_dir AS 'c:\esercizioAgostino\bad';

GRANT EXECUTE, READ, WRITE ON DIRECTORY data_dir TO carica WITH GRANT OPTION;
GRANT EXECUTE, READ, WRITE ON DIRECTORY log_dir TO carica WITH GRANT OPTION;
GRANT EXECUTE, READ, WRITE ON DIRECTORY bad_dir TO carica WITH GRANT OPTION;

-- sequence per tabella di log che controlla i singoli step
CREATE SEQUENCE carica.seq_id_log 
start with 1
increment by 1
NOCACHE;

-- sequence per tabella di log che controlla la run
CREATE SEQUENCE carica.seq_id_master
start with 1
increment by 1
NOCACHE;

-- CREA TABELLE: dati00, dati 01, dati01_scarti, wrk_log
CREATE TABLE carica.dati00 (
	cf VARCHAR2(100 BYTE),
	nome VARCHAR2(100 BYTE),
	cognome VARCHAR2(100 BYTE),
	salario VARCHAR2(100 BYTE)
);
CREATE TABLE carica.dati01 (
	cf VARCHAR2(16 BYTE),
	nome VARCHAR2(50 BYTE),
	cognome VARCHAR2(50 BYTE),
	salario number
);
CREATE TABLE carica.dati01_scarti (
	cf VARCHAR2(100 BYTE),
	nome VARCHAR2(100 BYTE),
	cognome VARCHAR2(100 BYTE),
	salario VARCHAR2(100 BYTE)
);
create table carica.wrk_log (
	id_log number,
	step number,
	sql_code number,
	stmt varchar2(2000),
	error_message varchar2(2000),
	procedura varchar2(100),
    note varchar(2000),
	d_ins date default sysdate
);

-- pacchetto che contient le funzioni f_is_positive, f_is_numeric, f_is_cf, f_is_valid, p_log
CREATE OR REPLACE PACKAGE carica.pkg_controls_01 AS
    FUNCTION f_is_positive (
        str IN VARCHAR2
    ) RETURN NUMBER;
    FUNCTION f_is_numeric (
        str IN VARCHAR2
    ) RETURN NUMBER;
    FUNCTION f_is_cf (
        str IN VARCHAR2
    ) RETURN NUMBER;
    FUNCTION f_is_valid (
        str IN VARCHAR2
    ) RETURN NUMBER;
	PROCEDURE p_log (
        p_step       IN NUMBER,
        p_sqlcode    IN NUMBER,
        p_stmt       IN VARCHAR2,
        p_sqlerror_m IN VARCHAR2,
        p_procedura  IN VARCHAR2,
		p_note 		 IN VARCHAR2
    );
END;
/


-- BODY del pacchetto
CREATE OR REPLACE PACKAGE BODY carica.pkg_controls_01 AS
-- funzione per controllare che il valore sia positivo
    FUNCTION f_is_positive (
        str IN VARCHAR2
    ) RETURN NUMBER IS
        v_number NUMBER(30);
    BEGIN
        v_number := TO_NUMBER ( str,'9999999999D999','NLS_NUMERIC_CHARACTERS = ''. ''');
        if v_number > 0 then
            RETURN 1;
        else
            return 0;
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

-- funzione per controllare che il valore sia un numero
    FUNCTION f_is_numeric (
        str IN VARCHAR2
    ) RETURN NUMBER IS
        v_number NUMBER(30);
    BEGIN
        v_number := TO_NUMBER ( str );
        RETURN 1;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;
-- funzione per controllare che il codice fiscale abbia il giusto formato
    FUNCTION f_is_cf (
        str IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
    	if REGEXP_LIKE(lower(str), '^[a-z]{6}[0-9]{2}[a-z]{1}[0-9]{2}[a-z]{1}[0-9]{3}[a-z]{1}$') then
    		return 1;
    	else 
    		return 0;
    	end if;
    END;
-- funzione per controllare che nome e cognome siano ok
    FUNCTION f_is_valid (
        str IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
    	if REGEXP_LIKE(lower(str), '^[a-z]+$') then
    		return 1;
    	else 
    		return 0;
    	end if;
    END;
-- procedura per caricare dati file di log
    PROCEDURE p_log (
        p_step       IN NUMBER,
        p_sqlcode    IN NUMBER,
        p_stmt       IN VARCHAR2,
        p_sqlerror_m IN VARCHAR2,
        p_procedura  IN VARCHAR2,
		p_note 		 IN VARCHAR2
    ) IS
		PRAGMA autonomous_transaction;
	BEGIN
		
		INSERT INTO wrk_log
		(
			id_log,
			step,
			sql_code,
			stmt,
			error_message,
			procedura,
			note,
			d_ins)
			values (
			seq_id_log.NEXTVAL,
            p_step,
            p_sqlcode,
            p_stmt,
            p_sqlerror_m,
            p_procedura,
			p_note,
            sysdate);
			COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            dbms_output.put_line('Errore p_log: '
                                 || to_char(sqlcode)
                                 || ': '
                                 || substr(sqlerrm, 1, 100));
    end;
/*	
	PROCEDURE p_log_master (
        p_id_run     IN NUMBER,
        p_status     IN VARCHAR2
    ) IS
        PRAGMA autonomous_transaction;    -- permette di eseguire il commit sulle colonne della insert di cui al punto seguente 
    BEGIN
        INSERT INTO wrk_audit_master (
            id_run,
            status,
            d_ins
        ) VALUES (
            seq_id_master.NEXTVAL,
            p_status,
            sysdate
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            dbms_output.put_line('Errore p_log_log: '
                                 || to_char(sqlcode)
                                 || ': '
                                 || substr(sqlerrm, 1, 100));

    END;
	*/
END;
/
exit;