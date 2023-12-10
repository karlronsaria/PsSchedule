<#
.HOWTO
$getScripts = "$pathTo\Get-Scripts.ps1"
& $getScripts | foreach { . $_ }

.LINK
Url: <https://stackoverflow.com/questions/65462679/why-powershell-exe-there-is-no-way-to-dot-source-a-script>
Retrieved: 2022_10_09
#>

return @(dir "$PsScriptRoot\script\*.ps1")
