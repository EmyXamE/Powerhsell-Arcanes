# -------------------------------------------
# Win10 Initial Setup Script
# Author: LB
# Version: 1.0
# -------------------------------------------

# ----------------
# Privacy Settings
# ----------------

# Disable Advertising ID
Write-Host "Disabling Advertising ID..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0

# Enable Advertising ID
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled"

# Disable Bing Search in Start Menu
Write-Host "Disabling Bing Search in Start Menu..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0

# Enable Bing Search in Start Menu
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled"

# Stop and disable Diagnostics Tracking Service
Write-Host "Stopping and disabling Diagnostics Tracking Service..."
try{
    Stop-Service "DiagTrack"
    Set-Service "DiagTrack" -StartupType Disabled
}
catch{
    Write-Host "$($_.Exception.Message) `n $($_.InvocationInfo.PositionMessage)"
}

# Enable and start Diagnostics Tracking Service
# Set-Service "DiagTrack" -StartupType Automatic
# Start-Service "DiagTrack"


# ----------------------------
# Remove unwanted applications
# ----------------------------

$appsToRemove = @(  "Microsoft.Wallet"
                    "Microsoft.SkypeApp"
                    "MicrosoftTeams"
                    "Microsoft.OneDriveSync"
                    "Microsoft.MicrosoftSolitaireCollection"
                    "Microsoft.WindowsFeedbackHub"
                    "Microsoft.People"
                    "Microsoft.ZuneVideo"
                    "Microsoft.GamingApp"
                    "Clipchamp.Clipchamp"
                    "Microsoft.ZuneVideo"
                    "Microsoft.BingNews"
                    "Microsoft.ZuneMusic"
                    "Microsoft.BingWeather"
                    "Microsoft.YourPhone"
                    "Microsoft.Getstarted"
                    "Microsoft.StorePurchaseApp"
					"Microsoft.WindowsMaps"
                    )
foreach($app in $appsToRemove){
    try{
		Get-AppxPackage | Where-Object Name -like "*$app*" | Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online
    }
    catch{
        Write-Host "Failed to erase $($package)"
        Write-Host "$($_.Exception.Message) `n $($_.InvocationInfo.PositionMessage)"
    }
}

# File Explorer Options
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0
#Stop-Process -processname explorer
#Start-Process Explorer.exe
# Change default Explorer view to "Computer"
Write-Host "Changing default Explorer view to `"Computer`"..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

# Change default Explorer view to "Quick Access"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo"
# SIG # Begin signature block
# MIIZ9gYJKoZIhvcNAQcCoIIZ5zCCGeMCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA+cInbXLGPPhkR
# AWR2UN3ZBFkepjiQErIcNQ1pTF/AeKCCE+cwggX6MIIE4qADAgECAhMaAAAAGFwU
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
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgEc0UOEj5F2Lqyulw0zJfhzt2ngETDsD4
# Vjk8kNmoB7YwDQYJKoZIhvcNAQEBBQAEggEAbLiZf0R8dAbqlL0Js0lLuy8a9tm1
# SikewAKJoZEhIpbwUXMhq/pY26mQ2A4O2gGWI4Q+xnqm3RsxIeKGdq8q+seBB3xZ
# IylHeuCwVaFR9MkF/eD4UW1RtvY+u9sK8V0aHlr5Exx0jZFnU5fbAPgVOCcg7KtB
# mk9SJG+hMBXDNxpEtdTsIlcjDqubtWiNC/qggX1LDD67vjr8HnrRHRegPgbZvD8L
# SufyUF5gLppM/Xwnc05tvyuihtK6sMDYk3NpcrtZHZjPEJhieqv1YYnax5E001cF
# 4O63SAFBaZxW6kKzceswjkIsBE/+qdl6ZU5H4OmFqPxsbioQSQ9rAa/kiqGCA0sw
# ggNHBgkqhkiG9w0BCQYxggM4MIIDNAIBATCBkTB9MQswCQYDVQQGEwJHQjEbMBkG
# A1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUg
# U3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQwDQYJYIZIAWUDBAICBQCgeTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNDA2MDQx
# MjI0MDlaMD8GCSqGSIb3DQEJBDEyBDAX3lJoD2ZkB2KK26zfL7pcxa9TFFP28DAP
# fkV1aElzELsCSW38c8/mBR0e45CmvMowDQYJKoZIhvcNAQEBBQAEggIAIPDbIV3a
# D1KNeGCvYEQEP+IxHfCCZLOdO931x/+e2bnxuNAqZDENU4XB02gN1fI7XrbJMaoW
# 52REnwUAff8rKg9ujWT0LGACv6Qzij2HAJ1/ezPIrsO6nwp2NJZiXW/WHSKqgVeD
# pjHM+cz4a0o/+UPmsg2zV6ojAZ1eJeJbMSbxxo3wrmjsVDL1eM43BcC7orru+Wwr
# 84tgJeDxBXpubZbcqE7kM2V+rfJLtsr+9vWoNgX5AA5Qg+9mUWYi2FiH4xuhwuMi
# 1dx7m4AkzJa+ByJgXRggbEyQhXKeFR6NUhxspZu0KWu/Uws3fafkwqxz1OVrgpWb
# V+gni5eDZIJ4MGOZehFOA89YNptgHp57R0j4RDVeX/jjqn7JOM1g9Jl3IOXyyYSB
# RCIVjAAS9I4aAwtufMpzSyqwck+wSpnblugmnh45MXflvdvKvazi0SaubOVchbnr
# Fkmp3R05rEqybjTw8Kdb8AELIsMNlE5EK13tUxELaUfS2rvY4/8c252ahw2RtzO3
# 8tsrCX7ryamK5ZUAFqAaj0r9kGLrzJ+u8aI7oV6gECvh7LkOJuIi8IZ0L56CxNJ5
# uTIRISg31iu2vbwLhaO+VrX8BDqe2mQLuPjhvIsDFggw5oN16BDyExrM59nQ3C8g
# 85/RW3H4oaUUpGshPCwVfx2TkGZ8Qw9/BOM=
# SIG # End signature block
