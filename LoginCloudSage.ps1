# LB 11/.1/2023
# Script de connexion en 1 click sur les connexions cloud Sage

# Recuperation des variables systemes renseignees par l'entree keepass depuis RDM
$Hote = '$HOST$'
$Login = '$USERNAME$'
$Password = '$PASSWORD$'

$VerbosePreference = 'Continue'

# definit une classe .NET Framework dans la session powershell
Add-Type -AssemblyName PresentationCore,PresentationFramework

# Creation d'un racourcie vers un objet (plus precisement un ComObjetc) wscript.shell
$wshell = New-Object -ComObject wscript.shell;

function Wait-Action {
<#
    .SYNOPSIS
        A script to wait for an action to finish.

    .DESCRIPTION
        This script executes a scriptblock represented by the Condition parameter continually while the result returns 
        anything other than $false or $null.

    .PARAMETER Condition
         A mandatory scriptblock parameter representing the code to execute to check the action condition. This code 
         will be continually executed until it returns $false or $null.
    
    .PARAMETER Timeout
         A mandatory integer represneting the time (in seconds) to wait for the condition to complete.

    .PARAMETER ArgumentList
         An optional collection of one or more objects to pass to the scriptblock at run time. To use this parameter, 
         be sure you have a param() block in the Condition scriptblock to accept these parameters.

    .PARAMETER RetryInterval
         An optional integer representing the time (in seconds) between the code execution in Condition.

    .EXAMPLE
        PS> Wait-Action -Condition { (Get-Job).State | where { $_ -ne 'Running' } -Timeout 10
        
        This example will wait for all background jobs to complete for up to 10 seconds.
#>

    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]$Condition,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [object[]]$ArgumentList,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]$RetryInterval = 5
    )
    try {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (-not (& $Condition $ArgumentList))) {
            Start-Sleep -Seconds $RetryInterval
            $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)
            Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
        }
        $timer.Stop()
        if ($timer.Elapsed.TotalSeconds -gt $Timeout) {     
            throw 'Action did not complete before timeout period.'         
        } else {
            Write-Verbose -Message 'Action completed before timeout period.'
        }
    } catch {
        # Write-Error -Message $_.Exception.Message
    }
}

# Definition des parametres du bouton
$ButtonType = [System.Windows.MessageBoxButton]::YesNo
$MessageIcon = [System.Windows.MessageBoxImage]::Warning
$MessageBody = "Ne plus toucher au clavier ou à la souris jusqu'à la fin de la connexion"
$MessageTitle = "Confirm box"
# Initialisation d'un message box via le racourcie $Box
$Box = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)

# Utilisation racourcie wshell pour mettre en focus le boutton
$wshell.AppActivate(($Box))

if ($Box -eq 'No')
{
    # Definition des parametres du bouton
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    $MessageIcon = [System.Windows.MessageBoxImage]::Stop
    $MessageBody = "Connexion annulee"
    $MessageTitle = "Confirm box"
    # Affichage button avec les variables definis au dessus
    $Box = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    # Utilisation racourcie wshell pour mettre en focus la fenetre souhaite
    $wshell.AppActivate(($Box))
    exit 1
}

# attente apparition fenetre "Securite Windows*" pendant 10 secondes max. Ca correspond à la phase 1 de la connexion.
Wait-Action -Condition {Get-Process | Where-Object {$_.MainWindowTitle -like "*Securite Windows*"}} -Timeout 10 -RetryInterval 1
# On stock dans la variable $a l'id du processus de la fenetre securite Windows
$a = Get-Process | Where-Object {$_.MainWindowTitle -like "*Securite Windows*"}


# On rentre dans la boucle si la variable $a est vide et donc que la fenetre "Securite Windows*" n'a pas ete trouve avant la fin du timeout
if (!$a)
    {
    # attente apparition fenetre "Remote Desktop Connection*" pendant 60 secondes max. Il s'agit de la 2 eme phase de connexion que l'on check. 
    # On rentre dans cette boucle uniquement si la premiere fenetre "Securite Windows*" n'a pas ete trouve.
    Wait-Action -Condition {Get-Process | Where-Object {$_.MainWindowTitle -like "*Remote Desktop Connection*"}} -Timeout 60 -RetryInterval 1
    $a = Get-Process | Where-Object {$_.MainWindowTitle -like "*Remote Desktop Connection*"}

        # Si on trouve la fenetre "Remote Desktop Connection*" on rentre dans le if pour afficher un message box qui indique un timeout et on sort du code.
        if (!$a)
        {
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageIcon = [System.Windows.MessageBoxImage]::Stop
        $MessageBody = "Erreur timed out fenetre introuvable merci de relancer ou contacter le SI"
        $MessageTitle = "Confirm box"
        $Box = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        $wshell.AppActivate(($Box))
        exit 1
        }

    # AppActivate = Focus sur la fenetre souhaite et suite d'action pour renseigner les champs
    # On rentre dans cette sequence uniquement si on est dejà connecte sur un autre serveur cloud
    $wshell.AppActivate(($a.id))
    Start-Sleep -seconds 4
    $wshell.sendkeys($Hote)
    $wshell.sendkeys("~")
    Start-Sleep -seconds 5
    $wshell.sendkeys($Password)
    Start-Sleep -seconds 2
    $wshell.sendkeys("~")

    }
    # Si on a trouve la fenetre "Securite Windows*" on rentre dans le else.
    else
    {
    $wshell.AppActivate(($a.id))
    Start-Sleep -seconds 4
    $wshell.sendkeys($Login)
    $wshell.sendkeys("{TAB}")
    Start-Sleep -seconds 2
    $wshell.sendkeys($Password)
    Start-Sleep -seconds 2
    $wshell.sendkeys("~")

    # suite à la premiere phase de connexion on attends 60 secondes max pour voir la fenetre "Remote Desktop Connection*" apparaitre.
    Wait-Action -Condition {Get-Process | Where-Object {$_.MainWindowTitle -like "*Remote Desktop Connection*"}} -Timeout 60 -RetryInterval 1
    
    # Si on ne trouve pas la fenetre "Remote Desktop Connection*" on rentre dans le if pour afficher un message box qui indique un timeout et on sort du code
     if (!$a)
        {
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageIcon = [System.Windows.MessageBoxImage]::Stop
        $MessageBody = "Erreur timed out fenetre introuvable merci de relancer ou contacter le SI"
        $MessageTitle = "Confirm box"
        $Box = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
        $wshell.AppActivate(($Box))
        exit 1
        }

    # Si on trouve la fenetre "Remote Desktop Connection*" on lance la deuxieme phase de connexion
    $wshell.AppActivate(($a.id))
    Start-Sleep -seconds 4
    $wshell.sendkeys($Hote)
    $wshell.sendkeys("~")
    Start-Sleep -seconds 5
    $wshell.sendkeys($Password)
    Start-Sleep -seconds 2
    $wshell.sendkeys("~")
    }


# SIG # Begin signature block
# MIIZ9gYJKoZIhvcNAQcCoIIZ5zCCGeMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDFSjokBMXko8pG
# hcIQNn4fk5AZ0FxUUVG1xStO6mYZYqCCE+cwggX6MIIE4qADAgECAhMaAAAAGFwU
# OFDNmFifAAAAAAAYMA0GCSqGSIb3DQEBCwUAME0xCzAJBgNVBAYTAkZSMRIwEAYD
# VQQHEwlNYXJzZWlsbGUxEDAOBgNVBAoTB0FyY2FuZXMxGDAWBgNVBAMTD0FSQ0FO
# RVMgUm9vdCBDQTAeFw0yMzA1MzExMjE0NDJaFw0zODA1MjcxMjE0NDJaMHYxFDAS
# BgoJkiaJk/IsZAEZFgRpbmZvMRcwFQYKCZImiZPyLGQBGRYHYXJjYW5lczETMBEG
# CgmSJomT8ixkARkWA2xhbjEYMBYGA1UECxMPQURNSU5JU1RSQVRFVVJTMRYwFAYD
# VQQDEw1Sb2JpbiBDSEFCQVVEMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEA0TN1R0c5Ryck/cHzyM41fLAZXIoUVOzq44khpYmzWtcUyBwHhgLnPjt5AI3m
# 7KyrXfv60GhcYAhyRn5rBX23pGGVIiT/t+cQQaBtoP2CduVYi60Uztu+WSowFcRv
# so1Z73BxuTx6pQ+czhXAsoXMgAYNjTUMGnkGhzFQ43vY7TXk0a2d4d7yYAQ40/hp
# lXauuWysddZMCrxHkGXtAPan5Oek2eSqSmaXblL9HBSy23bjb0ceJv2UvS0Z0ZLQ
# PieupE32B+6Lct6brobjU3PeUxAAOfwmjOy/MBqiAB3v+lXKhWdTJY/mIr7Z8H0H
# +a3XJrtrnFIfYxaszsxD6MCB+QIDAQABo4ICqDCCAqQwPQYJKwYBBAGCNxUHBDAw
# LgYmKwYBBAGCNxUIhtyZE4Xuy3WCxZcXgrrTcIavjT4Uhrrsd4OF6nwCAWQCAQkw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsGAQQBgjcV
# CgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFPZDrMNt1M989oOCHAshPR3Gx8XN
# MB8GA1UdIwQYMBaAFKeVtLX/UtxJDBdcAvmYSOuViaCFMIHZBgNVHR8EgdEwgc4w
# gcuggciggcWGgcJsZGFwOi8vL0NOPUFSQ0FORVMlMjBSb290JTIwQ0EsQ049QVJD
# RE9NMSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vydmlj
# ZXMsQ049Q29uZmlndXJhdGlvbixEQz1sYW4sREM9YXJjYW5lcyxEQz1pbmZvP2Nl
# cnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0
# cmlidXRpb25Qb2ludDCBzQYIKwYBBQUHAQEEgcAwgb0wgboGCCsGAQUFBzAChoGt
# bGRhcDovLy9DTj1BUkNBTkVTJTIwUm9vdCUyMENBLENOPUFJQSxDTj1QdWJsaWMl
# MjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERD
# PWxhbixEQz1hcmNhbmVzLERDPWluZm8/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVj
# dENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwNQYDVR0RBC4wLKAqBgorBgEE
# AYI3FAIDoBwMGnIuY2hhYmF1ZEBsYW4uYXJjYW5lcy5pbmZvMA0GCSqGSIb3DQEB
# CwUAA4IBAQBJ3VgZTl/DEpt3aaK5HCJ9rmYeZ9tDvgNraZGmkqolzVnmT0hlUoFf
# 8PHCSYoxxRHlDULU1GM5cSMymheU9EyhXMeUXGFcAx3bu6L0mVtfEtCAW8tVXEmg
# 9yacW1sv8F093s0qyZP9Hnx3MgD+IYpox4k1lYmAzMmlLf/a114wic+p96Utc+Xi
# MjRJjRyFQAK0csqhEFm5K2bDLF9JT3wCKG2FarOSnXg/XhJqwWkceJMmKG3CysTg
# yHRV5n1ObyLfH1PsZxC5SdOdG0p4B8FBlea+rOWucMJvxJX/GEMM+9vR0LfhC4Dr
# hGwUE7DCfthc/x7lcPUNMwNdgqwpbMENMIIG7DCCBNSgAwIBAgIQMA9vrN1mmHR8
# qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Ck5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUg
# VVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlm
# aWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAyMDAwMDAwWhcNMzgwMTE4MjM1OTU5
# WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw
# DgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNV
# BAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9AZg/IJC9nIAhVJO5z6A+U++zWsB2
# 1hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9UyUnkuyWPCE5u2hj8BBZJmbyGr1XEQ
# eYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzOWEnTv/M5u7mkI0Ks0BXDf56iXNc4
# 8RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0BKLwPDU+zkQGObp0ndVXRFzs0IXuX
# AZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBgfrhN9Q0/29DqhYyKVnHRLZRMyIw8
# 0xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUXx7gpGaQpL0bj3duRX58/Nj4OMGcr
# Rrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1IXMSHv2qyghYh3ekFesZVf/QOVQt
# Ju5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0bdonigbSlofe6GsO8Ft96XZpkyAc
# Spcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2fA179g6JTZ8qx+o2hZMmIklnLqEbA
# yfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmLQTkUAx4p+hulIq6lw02C0I3aa7fb
# 9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5WDLvbxhQiddPnTO9GrWdod6VQXqn
# gwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZssw
# HQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8GEgRVMA4GA1UdDwEB/wQEAwIBhjAS
# BgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBEGA1UdIAQK
# MAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVz
# dC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYI
# KwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5j
# b20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6
# Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIBAG1UgaUzXRbh
# tVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/RaoLlJWZApbGHLtVDb4n35nwDvQMOt
# 0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAcJlhc87QRD9XVw+K81Vh4v0h24URn
# bY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0llYIuM1cfwGWvnJSajtCN3wWeDmT
# k5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbks8VmBvbz1kteraMrQoohkv6ob1ol
# cGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALWPncEvAQ2ted3y5wujSMYuaPCRx3w
# Xdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/RoZSmTqo9CfUFbLfSZFrYKiLCS53x
# OV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1H3G/W0NdZT1QgW6r8NDT/LKzH7aZ
# lib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurwROYybxzrF06Uw3hlIDsPQaof6aFB
# nf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQxH/qEZ0eBsambTJdtDgJK0kHqv3s
# MNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsausfm2usg1XTN2jvF8IAwqd661ogKG
# uinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMIIG9TCCBN2gAwIBAgIQOUwl4XygbSeo
# ZeI72R0i1DANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9T
# ZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBp
# bmcgQ0EwHhcNMjMwNTAzMDAwMDAwWhcNMzQwODAyMjM1OTU5WjBqMQswCQYDVQQG
# EwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25lciAj
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKSTKFJLzyeHdqQpHJk4
# wOcO1NEc7GjLAWTkis13sHFlgryf/Iu7u5WY+yURjlqICWYRFFiyuiJb5vYy8V0t
# wHqiDuDgVmTtoeWBIHIgZEFsx8MI+vN9Xe8hmsJ+1yzDuhGYHvzTIAhCs1+/f4hY
# Mqsws9iMepZKGRNcrPznq+kcFi6wsDiVSs+FUKtnAyWhuzjpD2+pWpqRKBM1uR/z
# PeEkyGuxmegN77tN5T2MVAOR0Pwtz1UzOHoJHAfRIuBjhqe+/dKDcxIUm5pMCUa9
# NLzhS1B7cuBb/Rm7HzxqGXtuuy1EKr48TMysigSTxleGoHM2K4GX+hubfoiH2FJ5
# if5udzfXu1Cf+hglTxPyXnypsSBaKaujQod34PRMAkjdWKVTpqOg7RmWZRUpxe0z
# MCXmloOBmvZgZpBYB4DNQnWs+7SR0MXdAUBqtqgQ7vaNereeda/TpUsYoQyfV7Be
# JUeRdM11EtGcb+ReDZvsdSbu/tP1ki9ShejaRFEqoswAyodmQ6MbAO+itZadYq0n
# C/IbSsnDlEI3iCCEqIeuw7ojcnv4VO/4ayewhfWnQ4XYKzl021p3AtGk+vXNnD3M
# H65R0Hts2B0tEUJTcXTC5TWqLVIS2SXP8NPQkUMS1zJ9mGzjd0HI/x8kVO9urcY+
# VXvxXIc6ZPFgSwVP77kv7AkTAgMBAAGjggGCMIIBfjAfBgNVHSMEGDAWgBQaofhh
# GSAPw0F3RSiO0TVfBhIEVTAdBgNVHQ4EFgQUAw8xyJEqk71j89FdTaQ0D9KVARgw
# DgYDVR0PAQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwgwJTAjBggrBgEFBQcCARYX
# aHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQCMEQGA1UdHwQ9MDswOaA3
# oDWGM2h0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGlu
# Z0NBLmNybDB0BggrBgEFBQcBAQRoMGYwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQu
# c2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNydDAjBggrBgEF
# BQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQADggIB
# AEybZVj64HnP7xXDMm3eM5Hrd1ji673LSjx13n6UbcMixwSV32VpYRMM9gye9Ykg
# XsGHxwMkysel8Cbf+PgxZQ3g621RV6aMhFIIRhwqwt7y2opF87739i7Efu347Wi/
# elZI6WHlmjl3vL66kWSIdf9dhRY0J9Ipy//tLdr/vpMM7G2iDczD8W69IZEaIwBS
# rZfUYngqhHmo1z2sIY9wwyR5OpfxDaOjW1PYqwC6WPs1gE9fKHFsGV7Cg3KQruDG
# 2PKZ++q0kmV8B3w1RB2tWBhrYvvebMQKqWzTIUZw3C+NdUwjwkHQepY7w0vdzZIm
# dHZcN6CaJJ5OX07Tjw/lE09ZRGVLQ2TPSPhnZ7lNv8wNsTow0KE9SK16ZeTs3+AB
# 8LMqSjmswaT5qX010DJAoLEZKhghssh9BXEaSyc2quCYHIN158d+S4RDzUP7kJd2
# KhKsQMFwW5kKQPqAbZRhe8huuchnZyRcUI0BIN4H9wHU+C4RzZ2D5fjKJRxEPSfl
# sIZHKgsbhHZ9e2hPjbf3E7TtoC3ucw/ZELqdmSx813UfjxDElOZ+JOWVSoiMJ9aF
# Zh35rmR2kehI/shVCu0pwx/eOKbAFPsyPfipg2I2yMO+AIccq/pKQhyJA9z1XHxw
# 2V14Tu6fXiDmCWp8KwijSPUV/ARP380hHHrl9Y4a1LlAMYIFZTCCBWECAQEwZDBN
# MQswCQYDVQQGEwJGUjESMBAGA1UEBxMJTWFyc2VpbGxlMRAwDgYDVQQKEwdBcmNh
# bmVzMRgwFgYDVQQDEw9BUkNBTkVTIFJvb3QgQ0ECExoAAAAYXBQ4UM2YWJ8AAAAA
# ABgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgcfskbhTZHPJOAQwzSEYDs7SO1u0g+lVc
# cXzVZyiq4YQwDQYJKoZIhvcNAQEBBQAEggEANb4b16H2l1+wEhsbTJAAnlKC6RlK
# XhMloR98WwB0DLnMBPQH0pTAV22Huzy6fE6VhM6WsYZXObg9nv7u/yE9SrN/RUzM
# yzYXjS7X9HIjowk6zb+0gKs0J9FAeLfl3CVPbFc+fGJ43Bz68aHnZG5N457UMJV1
# C6SGQXQ4/U8Yf/ldog1vrtkscspmadhGd/B4w+PylYAPQFzPGSat8+Mnd2CkJR/Q
# wNZABJXSyiUDzRVoC7kLgCMW3GOODzXnKxzMTnIFHAw4lDsU90TCcaZx9VxJoYxE
# iW87pJKABjzepAVrlvSK5m/5ru8S+Vp4EOCx+GukYWKsEtgbtONo5L53vqGCA0sw
# ggNHBgkqhkiG9w0BCQYxggM4MIIDNAIBATCBkTB9MQswCQYDVQQGEwJHQjEbMBkG
# A1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUg
# U3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQwDQYJYIZIAWUDBAICBQCgeTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzEyMjEx
# NDQ1NTdaMD8GCSqGSIb3DQEJBDEyBDAqQFJ8spV6i0EAwdNsp6Zk7Xzajl/RK2e6
# Q8GUGeQe+hshC5jK0pDNhlBn/E4ywwEwDQYJKoZIhvcNAQEBBQAEggIAbKJ6xdLY
# 79ny+XTxGbUlwWVulQjZ3TncMuvZWWIdJuZBuQBJtfT0dRToGFQSnpQxeNiqGAiX
# GDTdZ85r/ZxbManDFlpYLv8HbnfhZ7+9ggieD/ceSy6cepCnRifc8wMctx21exkZ
# tMSnyxfU4Rq2gJ67QnNgIYHnFGfXx/+UL4POcgqgiczDyD/srHEDxmGCIKq40R0/
# ImA+h6Ui6hlzXAYRN0c1k7Lmd1AcExoeumRQBmB39M43KAszZRSh1NgHwIe73YQD
# uY7k0wYzbQaqh6u8QOJZoU0DPG7u6XNCaYm48X9yH/JRIdTvlOaMMniUkqqj/Dxw
# 7LNW+TW7vqDuYwa556reuwfDART5mXRFJPPXij22IBjWV/ZFNassnymHIyZph08K
# 4iqvDpRxaIuIBUKOGtmP6YGsAxKp3Vz18qecB1WGBEi1dpSdG6XzMEx2JIH9pKd4
# hADdUjL9T0yWeZEBOeLVfcCKLc5bt4G6HQ55p/FyKwWpgqXALtYlvSBECFebb4J0
# bQe95FoU37Zr9ZGe6G8nuOiahoTfiqRvbcK6od8IJjUqvcJ6DXQGVotO745ZL3iC
# J4Ee5B78r+bKFFYY3cYiEFgtsMFKKbGd6SVvRX/DiCBvru9w/ydKZCfEXhUGf5QI
# IFxLgo19lQdqEjC9HbAdux5iYkH/1m6JGLI=
# SIG # End signature block
