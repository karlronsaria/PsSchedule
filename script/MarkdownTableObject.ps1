<#
.SYNOPSIS
f: str -> bool
#>
function Test-MdTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputObject,

        [Switch]
        $AsBranch
    )

    Begin {
        $branchPattern =
            "(-(\s+\[( |x)\])?|\d+\.)\s*"
        $pattern =
            "^\s*$(if ($AsBranch) { "($branchPattern)?" })\|([^\|]+\|)+\s*$"
    }

    Process {
        return $InputObject -match $pattern
    }
}

<#
.SYNOPSIS
f: str -> P(str)
#>
function Select-MdTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputObject,

        [Switch]
        $PassThru
    )

    Begin {
        function Get-CaptureGroup {
            Param(
                $InputObject,

                [String]
                $Name
            )

            return ($InputObject.Groups `
                | where { $_.Name -eq $Name }).Captures `
                | foreach { $_.Value }
        }
    }

    Process {
        $result = [PsCustomObject]@{
            Note = @()
            Row = @()
            Cell = @()
        }

        $captures = [Regex]::Matches( `
            $InputObject, `
            "^\s*((?<note>-(\s+\[( |x)\])?|\d+\.)\s*)?(?<row>\|(\s*(?<cell>[^\|]+)\s*\|)+)\s*$" `
        )

        foreach ($capture in $captures) {
            if ($null -eq $capture) {
                return
            }

            $result.Note += Get-CaptureGroup $capture 'note'
            $result.Row += Get-CaptureGroup $capture 'row'
            $result.Cell += Get-CaptureGroup $capture 'cell'

            if ($PassThru) {
                $result | Add-Member `
                    -MemberType NoteProperty `
                    -Name InputObject `
                    -Value $InputObject
            }

            return $result
        }
    }
}

<#
.SYNOPSIS
f: str -> str?
#>
function Get-MdTableCell {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputObject
    )

    Process {
        foreach ($subitem in $InputObject) {
            $capture = [Regex]::Match( `
                $subitem, `
                "\|((?<cell>[^\|]+)\|)+" `
            )

            return $(if ($capture.Success) {
                $capture.Groups["cell"].Captures.Value.Trim()
            } else {
                $null
            })
        }
    }
}

function Test-MdTableRowIsVinculum {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputObject
    )

    Begin {
        $isVinculum = $true
    }

    Process {
        foreach ($subitem in $InputObject) {
            $isVinculum = $isVinculum -and $subitem -match "\s*-+\s*"
        }
    }

    End {
        return $isVinculum
    }
}

function Remove-MdStylers {
    Param(
        [String]
        $InputObject
    )

    # link
    # - url: https://www.markdownguide.org/cheat-sheet
    # - retrieved: 2023_09_13
    $stylers = @('``', '\*\*', '\*', '__', '_', '-', '~~', '==')

    foreach ($styler in $stylers) {
        $capture = [Regex]::Match( `
            $InputObject, `
            "(?<=^$styler).*(?=$styler$)" `
        )

        if ($capture.Success) {
            $InputObject = $capture.Value
        }
    }

    return $InputObject
}

function Add-MdTableRow {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $TableBuild,

        [String[]]
        $RowList,

        [Switch]
        $RemoveStyling
    )

    $RowList = $RowList | Get-MdTableCell

    if ($null -eq $RowList) {
        continue
    }

    if ($null -eq $TableBuild.Headings) {
        $TableBuild.Headings = if ($RemoveStyling) {
            $RowList | foreach {
                Remove-MdStylers $_
            }
        } else {
            $RowList
        }
    }
    elseif ($null -eq $TableBuild.Vinculum `
        -and ($RowList | Test-MdTableRowIsVinculum))
    {
        $TableBuild.Vinculum = $RowList
    }
    else {
        $TableBuild.Rows += @(@{ Row = $RowList })
    }
}

function ConvertTo-MdTable {
    Param(
        [PsCustomObject]
        $TableBuild
    )

    foreach ($item in $TableBuild.Rows) {
        $obj = [PsCustomObject]@{}
        $index = 0

        foreach ($heading in $TableBuild.Headings) {
            $obj | Add-Member `
                -MemberType NoteProperty `
                -Name $heading `
                -Value $item.Row[$index]

            $index = $index + 1
        }

        Write-Output $obj
    }
}

function New-MdTableBuild {
    return [PsCustomObject]@{
        Headings = $null
        Vinculum = $null
        Rows = @()
    }
}

<#
.SYNOPSIS
f: str -> tree
#>
function Get-MdTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputObject,

        [Switch]
        $RemoveStyling
    )

    Begin {
        $tableBuild = New-MdTableBuild
    }

    Process {
        foreach ($rowList in $InputObject) {
            $tableBuild | Add-MdTableRow `
                -RowList $rowList `
                -RemoveStyling
        }
    }

    End {
        return ConvertTo-MdTable `
            -TableBuild $tableBuild
    }
}

<#
.SYNOPSIS
f: tree -> str
#>
function Write-MdTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject[]]
        $InputObject
    )

    Begin {
        $list = @()
        $properties = @()
    }

    Process {
        $InputObject | foreach {
            $list += @($_)

            $properties += @($_.PsObject.Properties.Name | where {
                $_ -notin $properties
            })
        }
    }

    End {
        $lengths = @{}

        foreach ($property in $properties) {
            $lengths[$property] = $property.Length
        }

        $rows += @(foreach ($item in $list) {
            $row = @{}

            foreach ($property in $properties) {
                $value = if ($property -in $item.PsObject.Properties.Name) {
                    $item.$property
                } else {
                    ""
                }

                if ($value.Length -gt $property.Length) {
                    $lengths[$property] = $value.Length
                }

                $row[$property] = $value
            }

            $row
        })

        $str = "|"

        foreach ($property in $properties) {
            $str += " " + ("{0, -$($lengths[$property])}" -f $property) + " |"
        }

        Write-Output $str
        $str = "|"

        foreach ($property in $properties) {
            $str += " " + ("-" * $lengths[$property]) + " |"
        }

        Write-Output $str

        foreach ($row in $rows) {
            $str = "|"

            foreach ($property in $properties) {
                $str += " " + ("{0, -$($lengths[$property])}" -f $($row[$property])) + " |"
            }

            Write-Output $str
        }
    }
}

