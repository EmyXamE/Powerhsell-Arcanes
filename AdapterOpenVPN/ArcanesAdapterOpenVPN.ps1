# Création adaptateur openvpn ArcanesTAP ou renommage si existant
#LB 03/12/2021

# Environment
$logtime = Get-Date -Format "ddMMyyyyhhmmss"
# TEMP = %USERPROFILE%\AppData\Local\Temp
$tempdir = "$($env:TEMP)"
$preplog = "${tempdir}\ArcanesAdapterOpenvpn${logtime}.log"

# Functions
# TIP ! A function returns everything that is not captured by something else, to return unique values make use of global variables !
# Write to logile
function Write-Log ([string]$logmsg, [string]$logfile)
{
  $curtime = Get-Date -Format "dd/MM/yyyy hh:mm:ss"
  Write-Output "${curtime} ${logmsg}" | Out-File -Force -Append -FilePath $logfile
  ## DEBUG
  ##Write-Output "${logmsg} [${logfile}]"
}
$taparcanes = (Get-NetAdapter).Name | Select-String -Pattern "ArcanesTAP"
# check si variable taparcanes est different de NULL
if (!$taparcanes)
{
	# On stock dans openvpn_tap le résultat de la commande et de la recherche de la chaine de caractére "TAP-Windows Adapter V9 #[0-9]" puis on liste le résultat avec un résultat ascendant grace à Sort-Order et on récupére le dernier résultat de la liste
	$openvpn_tap = (Get-NetAdapter).InterfaceDescription | Select-String -Pattern "TAP-Windows Adapter V9 #[0-9]" | Sort-Object | Select-Object -Last 1
	# Check si openvpn_tap est différent de null 
	If ($openvpn_tap -ne $null)
	{
		#On stock dans openvpntapname le résultat de la commande get-netdapter qui remonte les interfaces réseaux et le filtre pour récup uniquement la ligne avec la description "TAP-Windows Adapter V9 #2" 
		#puis après le pipe on récupére le nom de l'interface
		$openvpntapname = Get-NetAdapter -InterfaceDescription $openvpn_tap | select -ExpandProperty Name
		Rename-NetAdapter -Name $openvpntapname -NewName "ArcanesTAP"
		Write-Log "the adaptater have been renamed with success as : ArcanesTAP" $preplog
	}
	else
	{
		"Création d'un Adaptateur OpenVPN" 
		# Le & est extremement important, c'est ce qui permet d'executer un exe avec des arguments dans powershell. Il faut aussi conserver des simples ' plutôt que des " dans ce cas la
		& 'C:\Program Files\OpenVPN\bin\tapctl.exe' create --name ArcanesTAP
		Write-Log "The adaptater have been created as : ArcanesTAP" $preplog
	}
}
else 
{
 # NOTHING TO DO
   exit 0
}
# FIN SCRIPT
# SIG # Begin signature block
# MIIZ9gYJKoZIhvcNAQcCoIIZ5zCCGeMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC3eHlGlM8xgR79
# 4SCZRVS1NxNyQ/oK0nrd+MLKtZhN0qCCE+cwggX6MIIE4qADAgECAhMaAAAAGFwU
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
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg24MOFmem5H1+VeifWkaDKcj2aCHCR+Tw
# Z9uPidDhzOkwDQYJKoZIhvcNAQEBBQAEggEAat6Kjfy+R3zhQkCzrNBGKa+YaC6c
# 8mBP/NfOYg05U419K3oXiWPEhPwTa4lJKarpwo5mbafDak83IcumBSmNet+CE4wy
# a9Ha18iLbxFt2Lb0i8c/uHaAMapipQCLLbPW02E+T9tXLOOzdiX0z9q09fx4RHYI
# 2AoEKa9Yb4XMmZ+bgrPK8dltb+UE1fraXgFLieqrwg29zdx0/1+f11zIlglI4m+j
# 7CJXConprTww+WpKS4JzNATUdH8bMCb9GR3LJDXFFNkfkucepDUPYgjk4Xh9jZav
# sKMOYYLRRTI9On+56BG9F+BN8+hfqhhjLdEo3BWNxEfkw+bSFFVHQdabrKGCA0sw
# ggNHBgkqhkiG9w0BCQYxggM4MIIDNAIBATCBkTB9MQswCQYDVQQGEwJHQjEbMBkG
# A1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUg
# U3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQwDQYJYIZIAWUDBAICBQCgeTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzA5MTEx
# NDQ2NDFaMD8GCSqGSIb3DQEJBDEyBDDabg8HJrY/LwEdF3/CJHlSaMfCSWtc6vei
# 53mz6mMd8dcGMYODBfexm9vommMciRgwDQYJKoZIhvcNAQEBBQAEggIAZrun3Su3
# P5yLgd7mgE/bHmyFqq/+Ub90A/R3rlh0gkxL8zzYYUQG7q87JTJWTCb3tIslo7GZ
# voxB5NbVU0PZsENnAVxnL2UdULaoBGamxpCk+eiVCUDIzO0yl1UAg6t25w++/UHG
# n9BCbLXHCiNG06+u2XBdpgrqMNM5n1aM99DIO2w991TTnc+cxpv3qkFJLzgqJsP5
# N19TEgIyZy1vkbQP/rlhwFQTbvXH0D2rJXjFU0VMQhCrKYd3dbWVSQjLNbSgHsZu
# 0p+5PJtPPPqHoxT8LYpK0neMKlj/Z2lnR0RvvGC1eZDyknDaQwJ2boCponA6+wVW
# Z4mGST779sMb0Rp/qfQNopObwJRUKr8liqKMqhFFbHvI5XNwXTQTyHLdLJyOmIyg
# U5I66+QM83FEVdT/IyVXVYDZVXv9ES6rfTwhUy0MLHOGo8vPdIUYElS2i5DBykOo
# 8waqHwQdWLe6OlbxFubx9qqO4c2uI27aGCnSXxwTbr9gVCARu6fBMtdjiUG81lah
# er6rIhJB2KlUcl8/oqdOe/Gw1mnWwvgSdg+430XPsA0C5dcdNya+IoX1I48ccNi5
# c9GutPoU2fZfQreMgMPqRAPVME5+ffIud1q7cbzaF19ajfqunK1j8Xut8gywRuSQ
# zUFBIovhrOfpeQpou/HS7OdSnS0IZOcDDXE=
# SIG # End signature block
