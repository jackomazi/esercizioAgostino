load DATA
BADFILE 'c:\esercizioAgostino\bad\bad_sqlloader.txt'
into table carica.dati00
fields terminated by ";"
TRAILING NULLCOLS
(cf, nome, cognome, salario)