# Creation adaptateur openvpn ArcanesTAP et ClientTAP ou renommage si existant pour permettre une double connexion OpenVPN
#V3
#LB 03/12/2021
#MB 28/12/2023


# Environment
$logtime = Get-Date -Format "ddMMyyyyhhmmss"
# TEMP = %USERPROFILE%\AppData\Local\Temp
$tempdir = "$($env:TEMP)"
$logdir = "${tempdir}\ArcanesAdapterOpenvpn"
$preplog = "${logdir}\ArcanesAdapterOpenvpn${logtime}.log"

if (-not (Test-Path -Path $logdir)) {
    New-Item -ItemType Directory -Path $logdir | Out-Null
}

# Functions
# TIP ! A function returns everything that is not captured by something else, to return unique values make use of global variables !
# Write to logile
function Write-Log ([string]$logmsg, [string]$logfile)
{
  $curtime = Get-Date -Format "dd/MM/yyyy hh:mm:ss"
  Write-Output "${curtime} ${logmsg}" | Out-File -Force -Append -FilePath $logfile
}



#verifie si il existe l'interface openvpn #4
$openvpn_tapDescr = (Get-NetAdapter).InterfaceDescription
$openvpn_tapName = (Get-NetAdapter).Name  
if ($openvpn_tapDescr | Select-String -Pattern "TAP-Windows Adapter V9 #4"){
    #si c'est le cas, il y a un probleme donc on arrete le script
    Write-log "Erreur : TAP-Windows Adapter V9 #4 Existant : Arret du script" $preplog
    exit 0
}
elseif (($openvpn_tapName | Select-String -Pattern "ArcanesTAP") -and ($openvpn_tapName | Select-String -Pattern "ClientTAP")) {
    Write-log "ArcanesTAP et clientTAP deja existant : Arret du script" $preplog
    exit 0
}
else{
    #Verifie les droits administrateur
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -eq $false) {
        Write-log "ERROR : Pas de droit adminisatrateur " $preplog
        exit 0
    }
    Write-log "Droits Admin : OK" $preplog

    #verifie si il existe l'interface openvpn #2
    if ($openvpn_tapDescr | Select-String -Pattern "TAP-Windows Adapter V9 #2"){
        #si elle existe, on la renomme Arcanes TAP
        $openvpntapname = Get-NetAdapter -InterfaceDescription $openvpn_tap | select -ExpandProperty Name
        Rename-NetAdapter -Name $openvpntapname -NewName "ArcanesTAP"
        Write-log "TAP-Windows Adapter V9 #2 Existant : renommage de l'interface en Arcanes TAP" $preplog    
    }
    else{
        #si elle n'existe pas on l'a cree et la nomme Arcanes TAP
        & 'C:\Program Files\OpenVPN\bin\tapctl.exe' create --name ArcanesTAP
        Write-log "TAP-Windows Adapter V9 #2 Non existant : creation de l'interface Arcanes TAP" $preplog
    }
    #verifie si il existe l'interface openvpn #3
    if ($openvpn_tapDescr | Select-String -Pattern "TAP-Windows Adapter V9 #3"){
        #si elle existe, on la renomme ClientTAP
        $openvpntapname = Get-NetAdapter -InterfaceDescription $openvpn_tap | select -ExpandProperty Name
        Rename-NetAdapter -Name $openvpntapname -NewName "ClientTAP"
        Write-log "TAP-Windows Adapter V9 #3 Existant : renommage de l'interface Client TAP" $preplog
        
    }
    else{
        #si elle n'existe pas, on la cree et la nomme ClientTAP
        & 'C:\Program Files\OpenVPN\bin\tapctl.exe' create --name ClientTAP
        Write-log "TAP-Windows Adapter V9 #3 Non existant : creation de l'interface Client TAP" $preplog
    }
}




# FIN SCRIPT
# SIG # Begin signature block
# MIIZ9gYJKoZIhvcNAQcCoIIZ5zCCGeMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBCTymWgEDTaxzQ
# cC8CYnWlg9KrG8rBunhYkWDS9MFSYqCCE+cwggX6MIIE4qADAgECAhMaAAAAGFwU
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
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg1IQbcVpGKeFO5Y6HE5cxL0LLY/yLmoj6
# UPloPGnya+EwDQYJKoZIhvcNAQEBBQAEggEAiTAHr5dblGtL6GBObvjM6i/G0kv2
# OikPVTe6HPe/enalbkihXahORuK0VtLG3x7v1K3FR99p4Yc2Socq55dCYPReq+Ko
# PjEF7rjnRShKSGjGT3N0hXMrZiVJPYkm1V+ONGTsWMRpmCLMqgr3MNiSAp3eqjZm
# XAZEFNYY6+uK9KAOV6+hstPYB2MX9C6M3We32oKFxMTnkEDBJFqVhJ2iqs08/bwW
# OJGMGSafD519wkNUk4Ud/LjTG2JSFvoAG0oRX56isD0VJT4Y8VZtr6sed8eMrMOK
# jNhkj0TZ9HEhgNlxpLXYt0QGUJhINfPwmW2fMcsK1rcUZvrYkNm/vKoRlaGCA0sw
# ggNHBgkqhkiG9w0BCQYxggM4MIIDNAIBATCBkTB9MQswCQYDVQQGEwJHQjEbMBkG
# A1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUg
# U3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQwDQYJYIZIAWUDBAICBQCgeTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzEyMjkw
# ODI1NTJaMD8GCSqGSIb3DQEJBDEyBDBUR5GowjAEy5+OWQWykRrmlvKWi8e0yWcy
# vFeAOctodiKubN6Cgyhl13IMc8lYs6swDQYJKoZIhvcNAQEBBQAEggIAhhtFaYHl
# K1TXVzDUpC0Bd+GKmQx5/j5ApGKiLEIn2RJYB3keBjNJS8lZkoaL2mT8yq2JhEv0
# bJYF8+B8rs4uMMUDpWwPjpw+xJqKQMymAQD2Q0Qjh3m5wjqO9v1/2q6/Cf474EOw
# YkK7zt6sJaoVYy3oHyRHq9t8rGq4KseE9UTT75yeK67EqVmj/N7M6s+slP2BFUSa
# Ai39Vs3/ntoIuITmBx2zwVTvTb2DOTOpp5erw0gguKUfUQ5vFsUd6vau+RCug2WA
# 9vv2BALnroXOsJ6DCAIdkdmWB6aFfY3Ecua+6AmPvCBR5us9c+28XX+LPROzm5em
# X6ItmyJksIQ7IPw2KisBx1ZXR9Vkwfsjk6AhJMM8yan7KsGOAJLp9I3zY1ZI8Jun
# T6fhov+PxZ6Q8McaB665UCzpnDT7XRPEU9kR2/smw1A7/te0FdK3cXmeLPPVfh/V
# +4i+xq9imtYVjiBbYCjYtbBxAyRoYPj2z/+EGQP/7Wseq9AZ4t0hJQ3H5aW2vSMS
# wr5YkVUj+f5jOn++2Ibut1VDx1rkwsx9HVqnBCkpO3Uy0wK5SCEkDQR0+stDMLfK
# RERNe4+i0G2IR6k3DWhxp7c1TQG9zbi3RwjUA1jpsK7WRVlpG9vmmHI6dXTQ18X2
# 0kjQdy2CPHBmaKolFeif2tGZNpq81Yls6w8=
# SIG # End signature block
