<#
.HOWTO
$getScripts = "$pathTo\Get-Demands.ps1"
& $getScripts | foreach { . $_ }

.LINK
Url: <https://stackoverflow.com/questions/65462679/why-powershell-exe-there-is-no-way-to-dot-source-a-script>
Retrieved: 2022-10-09
#>

return @(dir "$PsScriptRoot\demand\*.ps1" -EA Silent)
