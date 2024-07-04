$openVPNConfigFileObject = Get-ChildItem -Path $PSScriptRoot -Filter *.ovpn | Select-Object -First 1
$TAPAdapterName = "Arcanes"

if (!$openVPNConfigFileObject) {
  Write-Host -ForegroundColor White -BackgroundColor Red "No .ovpn file found"
  exit 1
}

$openVPNConfigFile = $openVPNConfigFileObject.FullName

$openVPNBin = (Get-Command -ErrorAction SilentlyContinue openvpn).Path
if (!$openVPNBin) {
  Write-Host -ForegroundColor White -BackgroundColor Red "openvpn path not found (missing env ?)"
  exit 1
}

Write-Output "OpenVPN binary path=$openVPNBin"

$adapter = Get-NetAdapter -Name $TAPAdapterName -ErrorAction Ignore
if(!$adapter) {
  Write-Host -BackgroundColor Yellow -ForegroundColor Black "TAP Adapter $TAPAdapterName does not exist, creation..."
  $TAPCTLBin = (Get-Command tapctl).Path
  if (!$TAPCTLBin) {
    Write-Host -ForegroundColor White -BackgroundColor Red "tapctl path not found (missing env ?)"
    exit 1
  }

  Start-Process -FilePath $TAPCTLBin -ArgumentList "create","--name",$TAPAdapterName -Wait
}

$adapter = Get-NetAdapter -Name $TAPAdapterName -ErrorAction Ignore
if(!$adapter) {
  Write-Host -ForegroundColor White -BackgroundColor Red "TAP Adapter $TAPAdapterName creation failed"
  exit 1
}

Set-Location $PSScriptRoot

#Identifie un port libre entre 50000 et 60000
$port = 50000
$portFound = $false
do {
  $portFound = $true
  $port = $port + 1
  $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction Ignore
  if ($listener) {
    $portFound = $false
  }
} while (!$portFound -and $port -lt 60000)

if (!$portFound) {
  Write-Host -ForegroundColor White -BackgroundColor Red "No free port found"
  exit 1
}

Write-Host -BackgroundColor Yellow -ForegroundColor Black "Port $port will be used"

Start-Process -Verb runas -FilePath $openVPNBin -ArgumentList "--config",$openVPNConfigFile,"--management","127.0.0.1 $port"

# stocke le port dans un fichier texte
$portFile = "$PSScriptRoot\port.txt"
$port | Out-File -FilePath $portFile -Encoding ascii
