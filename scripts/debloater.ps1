Write-Host "Executando Windows Debloater..."

function Clear-Host { }

& ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))

