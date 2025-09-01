
#write_log -ShellName "loader.ps1" -Message "Parametri passati: $($args[0]), $($args[1]), $($args[2])" -LogFile "$shell_log"
# param([Parameter(Mandatory=$false, ValueFromPipeline=$true)][string]%nomevariabile = 'default', ..])
param(
    # Metodo: deve essere uno tra SQLLOADER, EXTERNAL_TABLE, UTL_FILE
    #[Parameter(Mandatory = $true)]
    #[ValidateSet("SQLLOADER","EXTERNAL_TABLE","UTL_FILE")]
    [string]$metodo = "SQLLOADER",

    # Path del flusso
    #[Parameter(Mandatory = $true)]
    [string]$path_flusso = "c:\esercizioAgostino\data\dati.csv",

    # Path del log
    #[Parameter(Mandatory = $true)]
    [string]$shell_log_temp = "c:\esercizioAgostino\log\shell_log.log"
)


function write_log {
    param (
        [string]$ShellName = "loader.ps1",
        [string]$MessageType = "INFO",
        [string]$Message,			
        [string]$LogFile
    )

    $now = Get-Date
    $timestamp = $now.ToString("yyyy/MM/dd HH:mm:ss:fff")

    $logLine = "[$timestamp - $ShellName - $MessageType] $Message"

    Add-Content -Path $LogFile -Value $logLine
}

if (!(test-path -path "c:\esercizioAgostino\log\shell_log.log")){	# se il file shell_log non esiste
			$shell_log = "c:\esercizioAgostino\log\shell_log.log"
			new-item $shell_log		# crea file shell_log
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------"
			echo "-----------------------------------------------------------------"
			echo "INIZIO LOADER"
			write_log -ShellName "loader.ps1" -Message "INIZIO LOADER" -LogFile "$shell_log"
			write_log -ShellName "loader.ps1" -Message "Creato file log shell" -LogFile "$shell_log"
		}
		else{	# altrimenti, se il file shell_log esiste
			$shell_log = "c:\esercizioAgostino\log\shell_log.log"
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------" >> $shell_log
			echo "-----------------------------------------------------------------"
			echo "-----------------------------------------------------------------"
			echo "INIZIO LOADER"
			write_log -ShellName "loader.ps1" -Message "INIZO LOADER" -LogFile "$shell_log"
			write_log -ShellName "loader.ps1" -Message "Shell_log non creato perchè esiste già" -LogFile "$shell_log"
		}	
		
# rimuovo log FILE
#remove-item c:\esercizioAgostino\log\shell_log

#------------------------------------
#------------------------------------
# CONTROLLI SUI PARAMETRI
#------------------------------------
#------------------------------------

# assegnazione dei parametri alle variabili corrispondenti $metodo = $args[0] $path_flusso = $args[1]

# controllo se i path sono validi
#----------------------------------

# LOG
if (test-path -path "$shell_log_temp"){	# PATH OK
	$shell_log = $shell_log_temp
	write_log -ShellName "loader.ps1" -Message "Path log inserito ok" -LogFile "$shell_log"
	echo "Path log ok"
}else{	# PATH NON OK
	write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Path log non ok" -LogFile "$shell_log"
	echo "Path log non ok, deve essere un path valido"
	echo "FINE LOADER"
	echo "-----------------------------------------------------------------"
	echo "-----------------------------------------------------------------"
	exit 1
}

#----------------------------------
# FLUSSO
if (test-path -path "$path_flusso"){ # PATH OK
		write_log -ShellName "loader.ps1" -Message "Path flusso ok" -LogFile "$shell_log"
		echo "Path flusso ok"
	}else{	# PATH NON OK
		write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Path flusso non ok" -LogFile "$shell_log"
		echo "Path flusso non ok, deve essere un path valido"
		echo "FINE LOADER"
		echo "-----------------------------------------------------------------"
		echo "-----------------------------------------------------------------"
		exit 1
	}
# controllo se il file flusso non è vuoto
if ((get-item $path_flusso).length -eq 0){
	write_log -ShellName "loader.ps1" -MessageType "Error" -Message "File flusso vuoto" -LogFile "$shell_log"
	
	write_log -ShellName "loader.ps1" -Message "FINE LOADER ----- " -LogFile "$shell_log"
	echo "File di flusso vuoto"
	echo "FINE LOADER"
	echo "-----------------------------------------------------------------"
	echo "-----------------------------------------------------------------"
	exit 1
}else{
	write_log -ShellName "loader.ps1" -Message "File flusso non vuoto" -LogFile "$shell_log"
}

#----------------------------------
# METODO
if ($metodo.ToLower() -in @("sqlloader", "external_table", "utl_file")){ # lower case
	write_log -ShellName "loader.ps1" -Message "Metodo ok" -LogFile "$shell_log"
	echo "Metodo ok"
}else{
	write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Metodo non ok, deve essere SQLLOADER, EXTERNAL_TABLE o UTL_FILE" -LogFile "$shell_log"

	write_log -ShellName "loader.ps1" -Message "FINE LOADER ----- " -LogFile "$shell_log"
	echo "Metodo non ok, deve essere SQLLOADER, EXTERNAL_TABLE o UTL_FILE"
	echo "FINE LOADER"
	echo "-----------------------------------------------------------------"
	echo "-----------------------------------------------------------------"
	exit 1
}

write_log -ShellName "loader.ps1" -Message "Parametri usati: $metodo, $path_flusso, $shell_log" -LogFile "$shell_log"

#------------------------------------
#------------------------------------
# CREAZIONE ENVIRONMENT + CALL AL METODO
#------------------------------------
#------------------------------------
echo "INIZIO CREAZIONE ENV E CALL AL METODO"
echo "-----------------------------------------------------------------"
$config = Get-Content "c:\esercizioAgostino\connection.config"

foreach ($line in $config) {
    $parts = $line -split "=",2
    Set-Variable -Name $parts[0] -Value $parts[1]
}

# ricavo utente, passw, hostname e db dal file connection.config
# 

$output = & sqlplus $SYS $ENV # eseguo create_env.sql
$exitcode = $LASTEXITCODE

if ($exitCode -ne 0 -or ($output -match "ORA-")) {
	write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Codice errore sql: $exitcode" -LogFile "$shell_log"
	echo "Errore nella creazione environment, controlla file di log per codice errore"
	echo "FINE LOADER"
	echo "-----------------------------------------------------------------"
	echo "-----------------------------------------------------------------"
    exit 1
}

# messaggio di errore/tutto ok
write_log -ShellName "loader.ps1" -Message "Environment creato -----" -LogFile "$shell_log"
echo "Environment creato"
write_log -ShellName "loader.ps1" -Message "Comando sqlplus eseguito: sqlplus $SYS $ENV" -LogFile "$shell_log"


# echo "-----------------------------------------------------------------" >> $shell_log

# [YYYY/MM/DD HH:mm:ss:ms - NOME SHELL - TIPO MESSAGGIO] MESSAGGIO


# LOADERS

# SQLLOADER
if ($metodo -eq "SQLLOADER"){
	write_log -ShellName "loader.ps1" -Message "Metodo SQLLOADER iniziato -----" -LogFile "$shell_log"

	# FILE CTL
	$output = & sqlldr $CARICA $CONTROL data=$path_flusso
	if ($exitCode -ne 0) {
		write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Codice errore sql: $exitcode" -LogFile "$shell_log"
		echo "Errore nell'esecuzione del file ctl, controlla file di log per codice errore"
		echo "FINE LOADER"
		echo "-----------------------------------------------------------------"
		echo "-----------------------------------------------------------------"
		exit 1
	}
	write_log -ShellName "loader.ps1" -Message "Comando sqlldr eseguito: sqlldr $CARICA $CONTROL data=$path_flusso" -LogFile "$shell_log"
	
	# FILE SQL
	$output = & sqlplus $CARICA $LOAD_SQLLOADER 
	$exitcode = $LASTEXITCODE

	if ($exitCode -ne 0 -or ($output -match "ORA-")) {
		write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Codice errore sql: $exitcode" -LogFile "$shell_log"
		echo "Errore nell'esecuzione del metodo sqlloader, controlla file di log per codice errore"
		echo "FINE LOADER"
		echo "-----------------------------------------------------------------"
		echo "-----------------------------------------------------------------"
		exit 1
	}
	echo "SQLLOADER eseguito con successo!"
	write_log -ShellName "loader.ps1" -Message "Comando sqlplus eseguito: sqlplus $CARICA $LOAD_SQLLOADER " -LogFile "$shell_log"

}
# EXTERNAL_TABLE	
elseif ($metodo -eq "EXTERNAL_TABLE"){
	write_log -ShellName "loader.ps1" -Message "Metodo EXTERNAL_TABLE iniziato ----- " -LogFile "$shell_log"

	$output = & sqlplus $CARICA $LOAD_EXTERNAL_TABLE
	$exitcode = $LASTEXITCODE

	if ($exitCode -ne 0 -or ($output -match "ORA-")) {
		write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Codice errore sql: $exitcode" -LogFile "$shell_log"
		echo "Errore nell'esecuzione del metodo EXTERNAL_TABLE, controlla file di log per codice errore"
		echo "FINE LOADER"
		echo "-----------------------------------------------------------------"
		echo "-----------------------------------------------------------------"
		exit 1
	}
	echo "EXTERNAL_TABLE eseguito con successo!"
	write_log -ShellName "loader.ps1" -Message "Comando sqlplus eseguito: sqlplus $CARICA $LOAD_EXTERNAL_TABLE " -LogFile "$shell_log"

}
# UTL_FILE
elseif ($metodo -eq "UTL_FILE"){
	write_log -ShellName "loader.ps1" -Message "Metodo UTL_FILE iniziato -----  " -LogFile "$shell_log"

	$output = & sqlplus $CARICA $LOAD_UTL
	$exitcode = $LASTEXITCODE

	if ($exitCode -ne 0 -or ($output -match "ORA-")) {
		write_log -ShellName "loader.ps1" -MessageType "Error" -Message "Codice errore sql: $exitcode" -LogFile "$shell_log"
		echo "Errore nell'esecuzione del metodo UTL_FILE, controlla file di log per codice errore"
		echo "FINE LOADER"
		echo "-----------------------------------------------------------------"
		echo "-----------------------------------------------------------------"
		exit 1
	}
	echo "UTL_FILE eseguito con successo!"
	write_log -ShellName "loader.ps1" -Message "Comando sqlplus eseguito: sqlplus $CARICA $LOAD_UTL" -LogFile "$shell_log"

}

write_log -ShellName "loader.ps1" -Message "	FINE LOADER ----- " -LogFile "$shell_log"
echo "FINE LOADER"
echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"
exit 0