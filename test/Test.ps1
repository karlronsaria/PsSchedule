function Test-GetMarkdownTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Line,

        [Int]
        $DepthLimit = 4
    )

    Begin {
        function Test-EmptyObject {
            Param(
                [PsCustomObject]
                $InputObject
            )

            return 0 -eq @($InputObject.PsObject.Properties).Count
        }

        $content = @()
    }

    Process {
        $content += @($Line)
    }

    End {
        $what = $content `
            | Get-MarkdownTable_FromCat `
            | Get-HighestLevel_FromTable

        Write-Output @(
            ""
            "**************************************"
            "* --- Get-MarkdownTable_FromCat  --- *"
            "* --- Get-HighestLevel_FromTable --- *"
            "**************************************"
            ""
        )

        $what.Table | foreach {
            Write-Output $_
        }

        $table = $what.Table `
            | Get-TableTrim `
                -StartLevel $what.StartLevel

        Write-Output @(
            ""
            "**************************"
            "* --- Get-TableTrim  --- *"
            "**************************"
            ""
        )

        $table | foreach {
            Write-Output $_
        }

        if (-1 -ne $DepthLimit) {
            $table = $table | where {
                $_.Level -le $DepthLimit
            }
        }

        $tree = $table `
            | Get-MarkdownTree_FromTable `
                -HighestLevel $what.HighestLevel `
            | where { -not (Test-EmptyObject $_) }

        Write-Output @(
            ""
            "*************************************"
            "* --- Get-MarkdownTreeFromTable --- *"
            "*************************************"
            ""
        )

        return $tree
    }
}
