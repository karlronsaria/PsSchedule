<#
.DESCRIPTION
$getScripts = "$pathTo\Get-Test.ps1"

& $getScripts | foreach {
    . $_
}

.LINK
Url: https://stackoverflow.com/questions/65462679/why-powershell-exe-there-is-no-way-to-dot-source-a-script
Retrieved: 2022-10-09
#>

$scripts = dir @(
    "$PsScriptRoot\test\*.ps1"
    "$PsScriptRoot\demand\Debug\*.ps1"
)

return $scripts
