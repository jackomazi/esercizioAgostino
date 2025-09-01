-- .\loader.ps1 SQLLOADER c:\esercizioAgostino\data\dati.csv c:\esercizioAgostino\log\shell_log.log

SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT 9

-- STEP 1: TRONCA TABELLA 01
DECLARE
  v_stmt VARCHAR2(200);
  v_procedura varchar2(200):='LOAD_SQLLOADER';
BEGIN
	
	dbms_output.put_line('INIZIO TRONCATURA');
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
			p_note => 'STEP 1 - ERRORE in TRUNCATE TABLE 01'                                                                                                           );
end;
/

-- STEP 2: POPOLA TABELLA 01
DECLARE
  v_stmt VARCHAR2(2000);
  v_procedura varchar2(200):='LOAD_SQLLOADER';
BEGIN
	-- uso q'[] perchè mi dava problemi il to_number(...) per via degli apostrofi
	-- i 9 e il NLS_NUMERIC_CHARACTERS servono perchè il salario è scritto con i . anzichè le ,
	-- quindi va cambiato il formato
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
  v_procedura varchar2(200):='LOAD_SQLLOADER';
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