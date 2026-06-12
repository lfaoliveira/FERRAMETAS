Write-Host "Executando Windows Debloater..."

& ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))

