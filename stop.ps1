#récupère le port dans $PSScriptRoot\port.txt
#$port = Get-Content "$PSScriptRoot\port.txt"
$port = 50006

# Open a connection to the management interface
$tcpClient = New-Object System.Net.Sockets.TcpClient('127.0.0.1', $port)
$stream = $tcpClient.GetStream()

# Send the 'signal SIGTERM' command
$writer = New-Object System.IO.StreamWriter($stream)
$writer.WriteLine('signal SIGTERM')
$writer.Flush()

# Close the connection
$writer.Close()
$stream.Close()
$tcpClient.Close()

# Supprime le fichier texte
Remove-Item "$PSScriptRoot\port.txt"
