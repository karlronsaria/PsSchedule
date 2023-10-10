function Debug-Tree {
    Param(
        $InputObject,

        [ScriptBlock]
        $ForBranch = {
            Param(
                [String]
                $InputObject,

                [Int]
                $Level
            )

            Write-Output "$(" " * (2 * $Level))$InputObject"
        },

        [ScriptBlock]
        $ForLeaf = {
            Param(
                $InputObject,

                [Int]
                $Level
            )

            Write-Output "$(" " * (2 * $Level))$(if ($null -eq $InputObject) {
                "null"
            } else {
                "$($InputObject.GetType().Name): $InputObject"
            })"
        },

        [Int]
        $Level = 0
    )

    switch ($InputObject) {
        { $_ -is [PsCustomObject] } {
            $_.PsObject.Properties | where {
                $_.MemberType -eq 'NoteProperty'
            } | foreach {
                & $ForBranch `
                    -InputObject $_.Name `
                    -Level $Level

                Debug-Tree `
                    -InputObject $_.Value `
                    -ForBranch $ForBranch `
                    -ForLeaf $ForLeaf `
                    -Level ($Level + 1)
            }
        }

        default {
            & $ForLeaf `
                -InputObject $InputObject `
                -Level $Level
        }
    }
}

function Write-TreeDebugInfo {
    Param(
        $InputObject
    )

    Debug-Tree -InputObject $InputObject | foreach {
        if ($_ -match "^[^:]+: ") {
            Write-Host $_ -ForegroundColor Green
        }
        else {
            Write-Host $_
        }
    }
}

