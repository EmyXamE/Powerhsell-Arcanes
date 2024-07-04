Function Test-ADUserAuthentication {
    param(
        [parameter(Mandatory=$true)]
        [string]$ADUserLogin,
        [parameter(Mandatory=$true)]
        [string]$ADUserPassword)

        ((New-Object DirectoryServices.DirectoryEntry -ArgumentList "",$ADUserLogin,$ADUserPassword).psbase.name) -ne $null
}

$isAuthenticated = $false

while (-not $isAuthenticated) {
    $credential = Get-Credential
    $ADUserLogin = $credential.UserName
    $ADUserPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))

    if (Test-ADUserAuthentication -ADUserLogin $ADUserLogin -ADUserPassword $ADUserPassword) {
        $isAuthenticated = $true
    }
}
