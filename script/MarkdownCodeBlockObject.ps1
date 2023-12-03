function Test-MdCodeBlock {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputObject,

        [Switch]
        $AsBranch
    )

    Process {
        return $InputObject -match "^\s*``````"
    }
}

function Select-MdCodeBlock {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $InputObject
    )

    Process {
        $capture = [Regex]::Match( `
            $InputObject, `
            "^(?<indent>\s*)``````(?<lang>\S+)?"
        )

        return $([PsCustomObject]@{
            Success = $capture.Success
            Indent = $capture.Groups['indent']
            Language = $capture.Groups['lang']
        })
    }
}

function Add-MdCodeBlockRow {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $CodeBlock,

        [String[]]
        $Row
    )

    foreach ($line in $Row) {
        $CodeBlock.Lines += @(
            $line -replace "^$($CodeBlock.Indent)", ""
        )
    }
}

function Get-MdCodeBlock {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputObject,

        [String]
        $Language
    )

    Begin {
        $snippets = @()
        $snippet = $null
    }

    Process {
        foreach ($line in $InputObject) {
            if ($null -eq $snippet) {
                $blockStart = Select-MdTable `
                    -InputObject $line

                if (-not [String]::IsNullOrWhiteSpace($Language) `
                    -and $blockStart.Language.ToLower() `
                    -ne $Language.ToLower()
                ) {
                    continue
                }

                if ($blockStart.Success) {
                    $snippet = [PsCustomObject]@{
                        Lines = @()
                        Language = $blockStart.Language
                        Indent = $blockStart.Indent
                    }
                }

                continue
            }

            $blockEnd = $line | Test-MdCodeBlock `

            if ($blockEnd.Success) {
                $snippets += @($snippet)
                $snippet = $null
                continue
            }

            Add-MdCodeBlockRow `
                -CodeBlock $snippet `
                -Row $line
        }
    }

    End {
        return $snippets | foreach {
            [PsCustomObject]@{
                Lines = $_.Lines
                Language = $_.Language
            }
        }
    }
}
