# GET LAST VEEAM BACKUP STATUS PER VM
# JMJ 21/11/2022 GetVMBackup V3

<#
    # La variable $env:PSModulePath est modifie automatiquement lors de l'installation de la console Veeam
    # Ce code est utile si la console Veeam n est pas installe. A utiliser si le module est importe depuis un zip
    # The remote machine from which you run Veeam PowerShell commands must have the Veeam Backup & Replication Console installed.
    # Make sure PSModulePath includes Veeam Console
    $MyModulePath = "C:\Program Files\Veeam\Backup and Replication\Console\"
    $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
    if ($Modules = Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
        try {
            $Modules | Import-Module -WarningAction SilentlyContinue
            }
            catch {
                throw "Failed to load Veeam Modules"
                }
        }
    Get-Module -Name Veeam.Backup.PowerShell -ListAvailable 
#>

# param doit etre au debut du programme pour fonctionner
# il faut que le fichier passe en parametre soit un .json
param(
    [string][ValidatePattern("^.+\.json$")]
    $jsonFile=$PSScriptRoot+"\"+($MyInvocation.MyCommand.Name).Split(".")[0]+".json",
    [switch]$help
)
Set-Location -Path $PSScriptRoot -ErrorAction stop
# ---------------
# VARIABLES
# ---------------

# la variable doit etre prefixee de $global: pour etre utilisee dans la fonction WriteLog
# longueur du separateur dans les logs
$global:sepCount = 0
$global:scriptName = $MyInvocation.MyCommand.Name

# initialisation du chemin du fichier log avec la date de l'execution du programme (il y en a un par jour)
# le fichier log est dans le repertoire du script, pas de necessite de le mettre dans un repertoire dedie
$today = Get-Date -Format "dd-MM-yyyy"
$logFile = $PSScriptRoot + "\" + "GetVMBackup_" + $today + ".log"

$jsonHelp = @"
installer Veeam Backup Console (module)
syntax du fichier json
daysToCheck : nombre de jours pour considerer que le backup est trop ancien - normalement 1
cleanUpLogDays : nombre de jours avant la suppression des logs - valeur : int
displaySessions : affichage des jobs - valeur : true ou false
displaySummary : affiche si les vms sont bien backupees - valeur : true ou false
writeLog : creation d'un fichier log - valeur : true ou false
displayLog : affichage des logs - valeur : true ou false
displayHTML : displaySummary au format HTML - valeur : true ou false
sendMail : envoie le HTML par mail - valeur true ou false
mailServer : fqdn du serveur de mail - valeur : string
mailFrom : adresse mail source - valeur : string
mailTo : adresse mail destinataire - valeur : tableau ou chaine : ["val1","val2","val3"] ou "val"
"@

$HTMLheader = @"
<style>
H1 {font-family: Arial; font-size: 12px; font-weight:bold; color: black;}
H2 {font-family: Arial; font-size: 12px; background-color:yellow; color: black;}
H3 {font-family: Arial; font-size: 12px; color: red;}
H4 {font-family: Arial; font-size: 12px; color: purple;}
TABLE {font-family: Arial; font-size: 12px; border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {font-family: Arial; font-size: 12px; border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {font-family: Arial; font-size: 12px; background-color:white; color: green; border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
<title>
VBR Report
</title>
"@

# ---------------
# FONCTIONS
# ---------------

# Detail des jobs et des taches
function VBRDisplay([string]$bcol, [string]$fcol,[string]$msg){
    if($DisplaySessions -eq $true) { write-host -BackgroundColor $bcol -ForegroundColor $fcol "$msg" }
}

# Resume des VMs
function VMDisplay([string]$bcol, [string]$fcol,[string]$msg){
    if($DisplaySummary -eq $true) { write-host -BackgroundColor $bcol -ForegroundColor $fcol "$msg" }
}

# Gestion du log a l ecran et sur disque
function WriteLog(){
    param(
        [string]$msg,
        [switch]$end
    )
    $content = (Get-Date -Format "[dd/MM/yyyy HH:mm:ss] ") + $msg
    # calcul du nombre de tire de fin en fonction de la plus grande ligne
    if ($content.Length -gt $global:sepCount){
        $global:sepCount = $content.Length
    }
    if($DisplayLog -eq $true){Write-Host $content}
    if($writeLog -eq $true){
	    try{
            Add-Content -Path $logFile -Value $content
	    }
        catch{
		    Write-Error -Message "LOGFILE WRITE ERROR" -Category InvalidOperation -CategoryReason "PERMISSIONS" -CategoryTargetName "LOGFILE" -RecommendedAction "CHECK UAC"
		    return
        }
        if($end -eq $true){
            $sepLine = ""
            for($i=0;$i -lt $global:sepCount;$i++){$sepLine += "-"}
            Add-Content -Path $logFile -Value $sepLine
        }
    }
}

# Deconnecte les sessions VBR et VMWare
function DisconnectSessions(){
    WriteLog "Disconnecting all pending ESX sessions ..."
    $global:DefaultVIServer | foreach-object { if ($_.Name -ne $null) {Disconnect-VIServer -Server $_.Name -Force -Confirm:$false | Out-Null }}
    WriteLog "Disconnecting pending VBR session ..."
    if((Get-VBRServerSession) -ne $null) { DisConnect-VBRServer }
}

# Envoie de mail
function SendMail(){
    param($MF,$MT,$MS,$MB,[switch]$isUrgent,$attachment=$null)
    if ($sendMail -eq $true -or $isUrgent -eq $true){
        if($attachment -eq $null){
            try{
                # La fonction accepte une chaine de caractere ou un array pour -To
                # En conservant -BodyAsHtml la fonction peut envoyer du contenu non html, ce parametre sert a interpreter les balises html
                # Les caracteres speciaux ne sont pas interpretes
                Send-MailMessage -From $MF -To $MT -Subject $MS -Body $MB -BodyAsHtml -ErrorAction Stop -Encoding ([System.Text.Encoding]::UTF8) | Out-Null
            }
            catch{
                $message = "ERROR: Send-MailMessage(): " + $_.Exception.Message
                WriteLog $message
            }
        }
        else{
            try{
                Send-MailMessage -From $MF -To $MT -Subject $MS -Body $MB -BodyAsHtml -Attachments $attachment -ErrorAction Stop -Encoding ([System.Text.Encoding]::UTF8) | Out-Null
            }
            catch{
                $message = "ERROR: Send-MailMessage(): " + $_.Exception.Message
                WriteLog $message
            }
        }
    }
}

# Erreur fatale avec affichage et envoie de mail force
function FatalError($msg){

    $mailSubject = $global:scriptName + "@" + [system.environment]::MachineName + " : FATAL ERROR"
	Write-Error "FATAL ERROR : $msg" -Category InvalidOperation -CategoryReason "FATAL" -CategoryTargetName "UNKNOWN" -RecommendedAction "CHECK LOG FILE"
    WriteLog $msg -end
    # -isUrgent force l'envoie du mail
    $HTMLmsg = @"
    <!DOCTYPE html>
    <head>
    <meta http-equiv="Content-Type" content="text/html"; charset=UTF-8>
    </head>
    <html>
    <body>
    <H1>Error message :</H1>
    <p> $msg </p>
    <H1>Log File : </H1>
    <p> $logFile </p>"
    </body>
    </html>
"@
    SendMail $mailFrom $mailTo $mailSubject $HTMLmsg -isUrgent
    DisconnectSessions
    exit 1
}

# Chargement des modules
function CheckModules($mods){
    foreach ($mod in $mods){
        # Get-Module affiche les modules importes dans la session actuelle ou ceux qui peuvent etre importer depuis PSModulPath avec -ListAvailable
        # Get-Module prend en compte uniquement PSModulePath
        # On regarde si le module est charge
        $ModName = (Get-Module $mod).Name
        if ($ModName -eq $Empty){
            if((Get-Module $mod -ListAvailable).name -eq $empty){
                try{
                    WriteLog "Installing $mod Module ..."
                    # -errorAction stop obligatoire pour le try catch
                    Install-Module $mod -Allowclobber -Repository PSGallery -Scope AllUsers -Force -ErrorAction Stop | Out-Null
                }
                catch{
                    $installError = "Install-module() : " + $error[0]
                    FatalError $installError
                }
            }
            WriteLog "Importing $mod module ..."
            # Ajoute le module dans la session powershell actuelle
            # Les modules installes sont automatiquement importes dans la session powershell actuelle a partir de powershell 3.0
            # Slow start-up of PowerCLI: Go to Internet Options/Advanced tab/Uncheck Check for publishers certificate revocation
			try{
                Import-Module $mod -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue -Scope Global -Verbose:$false
            }
            catch{
                $installError = "Import-Module() : " + $error[0]
                FatalError $installError
            }
        }
        else{
            WriteLog "Module $mod is available"
        }
    }
}

# ---------------
# JSON
# ---------------
if($help -eq $true){
    Write-Host $jsonHelp
    exit 0
}
# Verification de l existence du fichier passe en parametre
if ((Test-Path -Path $jsonFile) -ne $true){ FatalError "Le fichier donne en parametre $jsonFile n'existe pas" }

# Importation du fichier json en un PSCustomObject
try{
    $json = Get-Content $jsonFile | ConvertFrom-Json
}
catch{
    $convertFromJsonError = "ConvertFrom-Json() : " + $error[0]
    FatalError $convertFromJsonError
}
# pas de controle des donnees du json, je pars du fait que c'est une personne competente qui modifie le fichier
# le type est automatique a condition que la syntaxe du json soit respectee (0-9 = int; "toto" = string; true | false = boolean;["toto","titi"] = liste)
$daysToCheck = $json.general.daysToCheck
$cleanUpLogDays = $json.general.cleanUpLogDays
$displaySessions = $json.general.displaySessions
$displaySummary = $json.general.displaySummary
$writeLog = $json.general.writeLog
$DisplayLog = $json.general.DisplayLog
$displayHTML = $json.general.displayHTML
# SMTP port 25
$sendMail = $json.general.sendMail
$PSEmailServer = $json.general.mailServer
$MailFrom = $json.general.mailFrom
$MailTo = $json.general.mailTo

# ---------------
# LOGS
# ---------------

# Suppression des logs vieux de plus de 3 jours
WriteLog "Erasing logs older than $cleanUpLogDays days"
Get-ChildItem $PSScriptRoot |
    Where Name -Match "^GetVMBackup_[0-9]{2}\-[0-9]{2}\-[0-9]{4}\.log$" |
    Where CreationTime -lt (Get-Date).AddDays(-$cleanUpLogDays) |
    Remove-Item -Force
# Suppression du log s'il est plus grand que 1 Mo au cas ou la tache planifiee boucle
if((Get-ChildItem $logFile).Length -gt (1*1000000)){
    WriteLog "WARNING : Erasing current log $logFile, the size is anormaly big"
    Remove-Item $logFile -Force
    $htmlMsg = "La taille du fichier log journalier est important et a donc ete supprime"
    $mailSubjecte = $global:scriptName + " sur " + [system.environment]::MachineName + " - WARNING : TAILLE FICHIER LOG"
    SendMail $mailFrom $mailTo $mailSubjecte $htmlMsg -isUrgent
    
}


# ---------------
# MODULES
# ---------------
# WARNING ! Install-Module need administrator rigths.
#           VMWare.PowerCLI : KB 80260: Bug log4j 32/64 bits, preferred solution: deinstall Crystal Report. (https://kb.vmware.com/s/article/80260)
#           Veeam.Backup.PowerShell ne peut pas etre installe avec install-module, il faut installer la console manuellement
#           The Veeam PowerShell Toolkit is automatically included when installing either Veeam Backup & Replication or the Veeam Backup & Replication Console.
#           (Import-Module "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1")

WriteLog "Checking modules ..."
CheckModules @("VMware.VimAutomation.Core", "Veeam.Backup.PowerShell")

# ---------------
# MAIN PROC
# ---------------

# Cleanup ESX actives sessions
DisconnectSessions

# Module configuration
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
# CSV Summary
# Loop on ESX servers
# WARNING ! Read guest properties need VMWare Tools.
foreach($esx in $json.esx.psobject.properties.value){
    $CSVSummary = @()
    $esxObj = $esx.psobject.properties
    # Connect to ESX and VBR
    WriteLog "Connecting to ESX host $($esxObj["esxhost"].value) ..."
    try {
        $conViServ = (Connect-ViServer -Server $esxObj["esxhost"].value -User $esxObj["esxuser"].value -Password $esxObj["esxpass"].value -ErrorAction Stop)
    } catch {
        Writelog "ERROR: Unable to connect to ESX host : $($error[0])"
        DisconnectSessions
        continue
	} 
    WriteLog "User : $($conViServ.User), Server : $($conViServ.Name), Port : $($conViServ.Port)"
    WriteLog "Connecting to VBR machine $($esxObj["vbrhost"].value) ..."
    # BAD ! Connect-VBRServer does not output anything usefull
    try {
        Connect-VBRServer -Server $esxObj["vbrhost"].value -User $esxObj["vbruser"].value -Password $esxObj["vbrpass"].value -ErrorAction Stop
    } catch {
        Writelog "ERROR: Unable to connect to VBR machine : $($error[0])"
        DisconnectSessions
        continue
	}
    $conVBRServ = Get-VBRServerSession
    WriteLog "User : $($conVBRServ.User), Server : $($conVBRServ.Server), Port : $($conVBRServ.Port)"
    
    # First get a list of all VMs from vCenter and add to hash table
    # --------------------------------------------------------------
    WriteLog "Getting VM list ..."
    $vms = @{}
    # Pas possible de voir ce qu'il y a dans Guest sans appeler la fonction Get-VM avec -name ou Get-VMGuest
    # Get-VMGuest ne marche pas avec le | foreach-object { $_ | select-object}
    foreach ($vm in Get-VM){
        # Pour la version 5.5 de VMWare il faut faire un Get-VMGuest pour avoir l'IP et Get-HardDisk pour avoir la taille des disques
        $sum = 0
        # Disque logique declare sur vmware, la situation peut etre differente au niveau de l os (linux LVM)
        # l objectif etant de faire la somme c est pareil
        (Get-HardDisk -VM $vm.Name).CapacityGB | ForEach-Object{$sum += $_}
        $vmGuest = Get-VMGuest -VM $vm.Name
        # separation des adresses par une virgule s'il y en a plusieurs
        # pas d adresse ipv4 pour TESTDMZ5
        $vmGuestMatchedIp = @()
        $dnsResolveList = @()
        $vmGuest.IPAddress | ForEach-Object{if($_ -match '(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'){
                                                $vmGuestMatchedIp += $_
                                                $dnsResolve = (Resolve-DnsName -Name $_ -Type PTR -ErrorAction SilentlyContinue).NameHost
                                                if($dnsResolve -ne $null){
                                                    Foreach($dnsName in $dnsResolve){
                                                        $dnsResolveList += $dnsName
                                                    }
                                                }
                                            }
                                           }
        # Tri des adresse ips par ordre croisant
        # [System.Version] va permettre de faire un trie sur une adresse ipv4 (4 nombres comme dans les versions)
        $matchedIP = ($vmGuestMatchedIp | Sort-Object -Property { [System.Version]$_ }) -join ", "
        # Trie des noms de domaine par ordre alphabetique
        $dnsResolveList = ($dnsResolveList | Sort-Object) -join ", "
        $toolsStatus = $vm.ExtensionData.Guest.toolsStatus | Out-String
        # status array defaulted to unprotected/NO_JOB
        $vms.Add($vm.Name, @("Unprotected",                                     #0
                             "",                                                #1
                             $vm.PowerState,                                    #2
                             "NO_JOB",                                          #3
                             $matchedIp,                                        #4
                             $vm.NumCpu,                                        #5
                             $vm.MemoryGB,                                      #6
                             [math]::Round($sum,2),                             #7
                             "",                                                #8
                             "",                                                #9
                             "",                                                #10
                             "",                                                #11
                             $vmGuest.HostName,                                 #12
                             $vmGuest.OSFullName,                               #13
                             $toolsStatus.substring(5),                         #14
                             $dnsResolveList,                                   #15
                             "",                                                #16
                             "",                                                #17
                             ""                                                 #18
                            )
                )
    VMDisplay White Black ($vm.Name + " : " + ($vms[$vm.Name] -join " | "))
    }
    
    # Second get all backup end replica job sessions history
    # ------------------------------------------------------
    WriteLog "Getting VBR Jobs list ..."
    $vbrsessions = Get-VBRBackupSession | Sort-Object {$_.CreationTime -as [datetime]} | Where-Object {$_.JobType -eq "Backup" -or $_.JobType -eq "Replica"}
    Writelog "BakchupSessions : $vbrsessions"
    # Third find last VMs successfull or running and failed backups in selected session
    # ---------------------------------------------------------------------------------    
    WriteLog "Getting VBR Tasks list ..."
    $unknownVMS = @()
    foreach ($jobSession in $vbrsessions){
        $duration = ($jobSession.EndTime - $jobSession.CreationTime) -split "\."
        $bsize = ([math]::Round(($jobSession.BackupStats.BackupSize)/1024/1024/1024,2)).ToString()
        $sesmsg = ">>> " + $jobSession.Name + "|" + $jobSession.JobType + "|" + $jobSession.Result + "|" + $jobSession.CreationTime + "|" + $duration[0] + "|" + $bsize
        if($jobSession.Result -eq "Success"){
            VBRDisplay "Green" "Black" "$sesmsg"
        }
        else{
            VBRDisplay "Red" "Black" "$sesmsg"
        }
        # One task per VM
        # les task sont des sauvegardes de machines
        foreach ($VMTask in ($jobSession.gettasksessions() | ForEach-Object { $_ | Select-object @{Name="VMname";Expression={$_.Name}}, @{Name="TaskTime";Expression={$_.Progress.StartTimeLocal}}, Status, Progress} )){
            if($vms.ContainsKey($VMTask.VMname)){
                $vmname = $VMTask.VMName
            }
            else{
                if($unknownVMS -notcontains $VMTask.VMname){
                    $unknownVMS += $VMTask.VMname
                }
                $vmname = $VMTask.VMname + " [UNKNOWN@" + $esxObj["esxhost"].value + "]"
            }
            $tskmsg = "    " + $vmname + "|" + $VMTask.Status + "|" + $VMTask.Progress.StartTimeLocal + "|" + $VMTask.Progress.Duration + "|" + [math]::Round(($VMTask.Progress.TransferedSize)/1024/1024/1024,2) + "|" + ([math]::Round(($VMTask.progress.avgSpeed)/1024/1024,0)) -replace("^0$","ERROR")
            VBRDisplay "Yellow" "Black" "$tskmsg"
            # on considere que tout ce qui n'est pas success, warning on running est en erreur 
            # on met en 'old' si le job est plus ancien que $daysToCheck
            if(($VMTask.Status -eq "Success") -or ($VMTask.Status -eq "Warning") -or ($jobSession.State -eq "Running")){
                $TaskStatus = $VMTask.Status.ToString()
                if($jobSession.CreationTime -lt (Get-Date).adddays(-$daysToCheck)) {
                   $TaskStatus = $TaskStatus + "(old)"
                }
                $lastStatus = $TaskStatus + ", " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss" $VMTask.Progress.StartTimeLocal)
                # on ecrase avec le dernier backup reussi
                # donnees ramenees en octets
                if($vms.ContainsKey($VMTask.VMname)){
                    $vms[$VMTask.VMname][0] = $lastStatus
                    $vms[$VMTask.VMname][1] = $VMTask.Progress.StartTimeLocal
                    $vms[$VMTask.VMname][3] = $jobSession.Name
                    $vms[$VMTask.VMname][8] = [math]::Round(($VMTask.Progress.TransferedSize)/1024/1024/1024,2)
                    $vms[$VMTask.VMname][9] = $jobSession.SessionInfo.JobAlgorithm
                    $vms[$VMTask.VMname][10] = $VMTask.Progress.Duration
                    $vms[$VMTask.VMname][11] = [math]::Round(($VMTask.progress.avgSpeed)/1024/1024,0)
                    $vms[$VMTask.VMname][17] = $jobsession.getjob().GetTargetRepository().name
                    $vms[$VMTask.VMname][18] = $VMTask.Progress.StopTimeLocal
                }
            }
            else {
                # on ecrase avec le dernier backup en erreur
                if($vms.ContainsKey($VMTask.VMname)){
                    # Message d'erreur du job
                    $errorMsg = ($jobsession.logger.GetLog().updatedrecords | ?{$_.status -eq "EFailed"} | select title)[1]
                    $errorMsg = ($errorMsg | Out-String).Split(":")[1]
                    $lastStatus = $lastStatus = $VMTask.Status.ToString() + ", " + (Get-Date -Format "dd/MM/yyyy HH:mm:ss" $VMTask.Progress.StartTimeLocal) + ", " + $errorMsg
                    $vms[$VMTask.VMname][16] = $lastStatus
                    $vms[$VMTask.VMname][3] = $jobSession.Name
                }
            }
        }
    }
    
    # Finally output VMs status in color coded format based on power and backup status, and add it to HTML summary object
    # -------------------------------------------------------------------------------------------------------------------
    $Summary = @()
    foreach ($vm in ($vms.GetEnumerator() | Sort-Object {$_.Name -as [string]})){
        $vmname = $vm.Name
        $vmstate = ($vms[$vmname])[0]
        $backday = ($vms[$vmname])[1]
        $vmpower = ($vms[$vmname])[2]
        $backjob = ($vms[$vmname])[3]
        $vmIP = ($vms[$vmname])[4]
        $vmCPU = ($vms[$vmname])[5]
        $vmRAM = ($vms[$vmname])[6]
        $vmDisk = ($vms[$vmname])[7]
        $backupSize = ($vms[$vmname])[8]
        $backupType = ($vms[$vmname])[9]
        $backupDuration = ($vms[$vmname])[10]
        $avgSpeed = ($vms[$vmname])[11]
        $hostname = ($vms[$vmname])[12]
        $VMOS = ($vms[$vmname])[13]
        $VMToolsStatus = ($vms[$vmname])[14]
        $FQDN = ($vms[$vmname])[15]
        $lastFailed = ($vms[$vmname])[16]
        $target = ($vms[$vmname])[17]
        $endTime = ($vms[$vmname])[18]
        # mise en couleur des colonnes qui posent probleme
        # $vmstate contient "status[(old)], date"
        if($vmstate -like "*(old),*") {
            $htmlName = "<H2>" +$vmname+ "</H2>"
            $htmlState = "<H4>" +$vmstate+ "</H4>"
            VMDisplay DarkBlue Red "$vmname [$backjob] is $vmpower and was NOT backed up in the past $DaysToCheck day(s)"
        }
        elseif($vmstate -eq "Unprotected"){
            $htmlName = "<H2>" +$vmname+ "</H2>"
            $htmlState = "<H3>" +$vmstate+ "</H3>"
            VMDisplay DarkBlue Red "$vmname [$backjob] is $vmpower and seems to have NEVER be backed up"
        }
        elseif($vmstate -notlike "Success,*"){
            $htmlName = $vmname
            $htmlState = "<H4>" +$vmstate+ "</H4>"
            VMDisplay DarkBlue Magenta "$vmname [$backjob] is $vmpower and last backup seems not to be really successful"
        }
        else{
            $htmlName = $vmname
            $htmlState = $vmstate
            VMDisplay DarkBlue Green "$vmname [$backjob] is $vmpower and was last backed up on $backday"
        }
        if($vmpower -like "*Off*"){
            $htmlName = "<H2>" +$vmname+ "</H2>"
            $htmlPower = "<H3>" +$vmpower+ "</H3>"
        }
        else{
            $htmlPower = $vmpower
        }
        if($VMToolsStatus -notlike "*Ok*"){
            $htmlName = "<H2>" +$vmname+ "</H2>"
            $htmltools = "<H3>" +$VMToolsStatus+ "</H3>"
        }
        else{
            $htmltools = $VMToolsStatus
        }
        # Update HTML Object
        $Summary += New-Object PSObject -Property @{
                                                    VMName = $htmlName
                                                    Status = $htmlState
                                                    LastFailed = $lastFailed
                                                    VMPower = $htmlPower
                                                    LastJob = $backJob
                                                    VMIP = $vmIP
                                                    VMCPU = $vmCPU
                                                    VMRAM = $vmRAM
                                                    VMDisk = $vmDisk
                                                    BackupSize = $backupSize
                                                    BackupType = $backupType
                                                    Duration = $backupDuration
                                                    AvgSpeed = $avgSpeed
                                                    Hostname = $hostname
                                                    VMOS = $VMOS
                                                    ToolsStatus = $htmlTools
                                                    FQDN = $FQDN
                                                    Target = $target
                                                   }
        $CSVSummary += [PSCustomObject]@{vm=$vmName;host=$esxObj["vbrhost"].value;job=$backJob.split("(")[0];target=$target;date_debut=$backday;date_fin=$endTime;duree="$backupDuration"}
        # Export CSV
        # Creation du fichier avec SEP=, au debut puis ajout du csv (moins de code que creer le csv puis le reecrire avec SEP=, au debut)
        # Fichier de petite taille donc memoire ok
        Set-Content -Path .\GetVMBackup2.csv -Value "SEP=,"
        $CSVSummary | ConvertTo-Csv -NoTypeInformation | Add-Content -Path .\GetVMBackup2.csv
    }
    # Format summary to HTML File
    # BAD ! There is no parameter on the ConvertTo-Html cmdlet to prevent the conversion of special characters, make use of HtmlDecode method to convert back to HTML equivalents.
    $Pre = "<H1>$($esxObj["esxhost"].value) GetVMBAckup($DaysToCheck days)</H1>"
	$htmlunknown = ""
    if($unknownVMS.count -gt 0) {
        $htmlunknown = "<H3>VMs qui ont une tache Veeam mais qui ne sont pas dans la liste des VMs ESX: " + $unknownVMS -join "; " + "</H3>"
    }
    $Post = "$htmlunknown <H1>VBR host: $($esxObj["vbrhost"].value) </H1>"
    $HTMLFile = "$($esxObj["esxhost"].value)VMBackups.html"
    $MailSubject = "Veam Backup Report $($esxObj["esxhost"].value)@$($esxObj["vbrhost"].value) ($DaysToCheck)"
    Add-Type -AssemblyName System.Web
    $HTMLSummary = ($Summary | Select VMName,
                                      Status,
                                      LastFailed,
                                      LastJob,
                                      BackupType,
                                      Target,
                                      @{N="Size (GB)";E={$_.BackupSize}},
                                      Duration,
                                      @{N="Speed (MB/s)";E={$_.AvgSpeed}},
                                      VMPower,
                                      VMIP,
                                      Hostname,
                                      FQDN,
                                      VMCPU,
                                      @{N="VMRAM (GB)";E={$_.VMRAM}},
                                      @{N="VMDisk (GB)";E={$_.VMDisk}},
                                      VMOS,
                                      ToolsStatus |
                               ConvertTo-HTML -Head $HTMLheader -PreContent $Pre -PostContent $Post)
    $HTMLDecode = [System.Web.HttpUtility]::HtmlDecode($HTMLSummary)
    $HTMLDecode | Out-File $HTMLFile
    # Display HTML File
    if ($displayHTML -eq $true){Invoke-Item $HTMLFile}
    # Send HTML summary by email
    SendMail $mailFrom $mailTo $MailSubject $HTMLDecode ".\GetVMBackup2.csv"
    # Disconnect from current ESX and VBR machines
    DisconnectSessions
}


# ----
# EXIT
# ----
WriteLog "End of GetVMBackup.ps1 script" -end
#END