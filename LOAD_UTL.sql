-- .\loader.ps1 UTL_FILE c:\esercizioAgostino\data\dati.csv c:\esercizioAgostino\log\shell_log.log


set serveroutput on;
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT 9
-- STEP 0.1: crea procedura per importare i dati
CREATE OR REPLACE PROCEDURE import_data (file_name IN VARCHAR2)
IS
	F UTL_FILE.FILE_TYPE;
	FBAD UTL_FILE.FILE_TYPE;
	REC VARCHAR2(2000);
BEGIN
	DELETE DATI00;
	COMMIT;
	F := UTL_FILE.FOPEN ( 'DATA_DIR', file_name, 'R' );		-- file csv da cui leggere i record
	FBAD := UTL_FILE.FOPEN('BAD_DIR', 'bad_utl.log', 'A');	-- file per gli scarti
	
	utl_file.get_line(F, REC);
	IF UTL_FILE.IS_OPEN(F) THEN
	LOOP
		BEGIN
			utl_file.get_line(F, REC);
			IF REC IS NOT NULL THEN 
				-- '[^;]+' indica di prendere un insieme di caratteri che non sia un ;, 
				if length(regexp_substr(REC, '[^;]+', 1, 1))<=100 or regexp_substr(REC, '[^;]+', 1, 1) = NULL and 
					length(regexp_substr(REC, '[^;]+', 1, 2))<=100 or regexp_substr(REC, '[^;]+', 1, 1) = NULL and
					length(regexp_substr(REC, '[^;]+', 1, 3))<=100 or regexp_substr(REC, '[^;]+', 1, 1) = NULL and
					length(regexp_substr(REC, '[^;]+', 1, 4))<=100 or regexp_substr(REC, '[^;]+', 1, 1) = NULL
				THEN
					INSERT INTO DATI00 ( CF, NOME, COGNOME, SALARIO ) VALUES (
						regexp_substr(REC, '[^;]+', 1, 1),
						regexp_substr(REC, '[^;]+', 1, 2),
						regexp_substr(REC, '[^;]+', 1, 3),
						regexp_substr(REC, '[^;]+', 1, 4)
				);
				else 
					UTL_FILE.PUT_LINE(FBAD, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') ||'		' || REC);
				end if;
			ELSE
				EXIT;
			END IF;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			EXIT;
		END; -- END BEGIN
	COMMIT;
	END LOOP;
	END IF;
	UTL_FILE.FCLOSE(F);
	UTL_FILE.FCLOSE(FBAD);
END import_data;
/
execute import_data('dati.csv');

-- STEP 1: TRONCA TABELLA 01
DECLARE
  v_stmt VARCHAR2(200);
  v_procedura varchar2(200):='LOAD_UTL';
BEGIN
	v_stmt := 'TRUNCATE TABLE DATI01';
	execute immediate v_stmt;
	
	PKG_CONTROLS_01.p_log( p_step => 1, 
							p_sqlcode => NULL, 
							p_stmt => v_stmt,
                            p_sqlerror_m => NULL, 
							p_procedura => v_procedura, 
							p_note => 'STEP 1 - TRUNCATE TABLE 01'
							);

    EXCEPTION
		WHEN OTHERS THEN
		PKG_CONTROLS_01.p_log(
			p_step => 1, 
			p_sqlcode => sqlcode, 
			p_stmt => v_stmt,
			p_sqlerror_m => sqlerrm, 
			p_procedura => v_procedura, 
			p_note => 'STEP 1 - ERRORE in TRUNCATE TABLE 01'
                                                                                                               );
end;
/
-- STEP 2: POPOLA TABELLA 01
DECLARE
  v_stmt VARCHAR2(2000);
  v_procedura varchar2(200):='LOAD_UTL';
BEGIN
	v_stmt := q'[
    INSERT /* + APPEND */ INTO DATI01 (cf, nome, cognome, salario)
    SELECT cf, nome, cognome,
           TO_NUMBER(salario,'9999999999D999','NLS_NUMERIC_CHARACTERS = ''. ''')
    FROM dati00
    WHERE PKG_CONTROLS_01.f_is_cf(cf) = 1
      AND PKG_CONTROLS_01.f_is_positive(salario) = 1
      AND PKG_CONTROLS_01.f_is_valid(nome) = 1
      AND PKG_CONTROLS_01.f_is_valid(cognome) = 1
  ]';
	execute immediate v_stmt;
	commit;
	PKG_CONTROLS_01.p_log( p_step => 2, 
							p_sqlcode => NULL, 
							p_stmt => v_stmt,
                            p_sqlerror_m => NULL, 
							p_procedura => v_procedura, 
							p_note => 'STEP 2 - POPOLA TABELLA 01'
							);
	EXCEPTION
		WHEN OTHERS THEN
			PKG_CONTROLS_01.p_log(
				p_step => 2, 
				p_sqlcode => sqlcode, 
				p_stmt => v_stmt,
				p_sqlerror_m => sqlerrm, 
				p_procedura => v_procedura, 
				p_note => 'STEP 2 - ERRORE in POPOLA TABELLA 01'
                                                                                                               );
end;
/
-- STEP 3: POPOLA TABELLA 01 SCARTI
DECLARE
  v_stmt VARCHAR2(2000);
  v_procedura varchar2(200):='LOAD_UTL';
BEGIN
	v_stmt := 'INSERT /* + APPEND */
				INTO dati01_scarti
				(cf, nome, cognome, salario)
				SELECT cf, nome, cognome, salario
				from dati00
				WHERE
				PKG_CONTROLS_01.f_is_cf(cf) = 0 or 
				PKG_CONTROLS_01.f_is_positive(salario)= 0 or
				PKG_CONTROLS_01.f_is_valid(nome)= 0 or
				PKG_CONTROLS_01.f_is_valid(cognome)= 0
				';
	execute immediate v_stmt;
	commit;
	PKG_CONTROLS_01.p_log( p_step => 3, 
							p_sqlcode => NULL, 
							p_stmt => v_stmt,
                            p_sqlerror_m => NULL, 
							p_procedura => v_procedura, 
							p_note => 'STEP 3 - POPOLA TABELLA SCARTI 01'
							);
	EXCEPTION
		WHEN OTHERS THEN
			PKG_CONTROLS_01.p_log(
				p_step => 3, 
				p_sqlcode => sqlcode, 
				p_stmt => v_stmt,
				p_sqlerror_m => sqlerrm, 
				p_procedura => v_procedura, 
				p_note => 'STEP 3 - ERRORE in POPOLA TABELLA SCARTI 01'
                                                                                                               );
end;
/
exit;