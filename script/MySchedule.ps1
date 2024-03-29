# # todo
# - [ ] test
function Find-MyTree {
    [CmdletBinding(DefaultParameterSetName = "Named")]
    Param(
        [Parameter(ParameterSetName = 'Named')]
        [ArgumentCompleter({
            # A fixed list of parameters is passed to an argument-completer
            # script block.
            # Here, only two are of interest:
            #  * $wordToComplete:
            #      The part of the value that the user has typed so far,
            #      if any.
            #  * $preBoundParameters (called $fakeBoundParameters
            #    in the docs):
            #      A hashtable of those (future) parameter values specified
            #      so far that are side effect-free (see above).
            # ---
            # link
            # - url: <https://stackoverflow.com/questions/65892518/tab-complete-a-parameter-value-based-on-another-parameters-already-specified-va>
            # - retrieved: 2023_10_10
            Param(
                $cmdName,
                $paramName,
                $wordToComplete,
                $cmdAst,
                $preBoundParameter
            )

            $setting =
                cat "$PsScriptRoot\..\res\setting.json" `
                | ConvertFrom-Json

            $dirs = (dir $setting.SearchDirectory -Directory).Name

            $suggestions = if ($wordToComplete) {
                $dirs | where { $_ -like "$wordToComplete*" }
            }
            else {
                $dirs
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $dirs
            })
        })]
        [String]
        $Subdirectory,

        [Parameter(ParameterSetName = 'Named')]
        [String[]]
        $Tag,

        [Parameter(ParameterSetName = 'Named')]
        [ValidateSet('Print', 'Tree', 'Cat', 'Edit', 'Start')]
        [String]
        $Mode,

        [Parameter(ParameterSetName = 'Named')]
        [String]
        $Directory,

        [Parameter(ParameterSetName = 'Named')]
        [Int]
        $DepthLimit,

        [Switch]
        $NoHints,

        [Parameter(
            ParameterSetName = 'Inferred',
            Position = 0
        )]
        [String[]]
        $Arguments
    )

    function Find-Tag {
        Param(
            [String[]]
            $Haystack,

            [String[]]
            $Needle
        )

        $found = $false

        foreach ($subneedle in $Needle) {
            $found = $found -or $subneedle -in $Haystack

            if ($found) {
                break
            }
        }

        $found
    }

    $setting =
        cat "$PsScriptRoot\..\res\setting.json" `
        | ConvertFrom-Json

    Set-Variable `
        -Option Constant `
        -Name 'const' `
        -Value @([PsCustomObject]@{
            SENTINEL_DEPTH_LIMIT = -1
            DEFAULT_MODE = 'Print'
        })

    if ($PsCmdlet.ParameterSetName -eq 'Inferred') {
        $path = $setting.SearchDirectory
        $subdirectories = (dir $path -Directory).Name
        $validModes = @('Print', 'Tree', 'Cat', 'Edit')

        foreach ($arg in $Arguments) {
            if (-not $DepthLimit `
                -and ($arg -is [Int] `
                -or $arg -eq '^-?\d+$'))
            {
                $DepthLimit = [Int]$arg
            }
            elseif (-not $Mode `
                -and $arg -in $validModes)
            {
                $Mode = $arg
            }
            elseif (-not $Subdirectory `
                -and $arg -in $subdirectories)
            {
                $Subdirectory = $arg
            }
            elseif (-not $Tag) {
                $Tag = $arg
            }
        }
    }

    if (-not $Mode) {
        $Mode = $const.DEFAULT_MODE
    }

    if (-not $Directory) {
        $Directory = $setting.SearchDirectory
    }

    if (-not $DepthLimit) {
        $DepthLimit = $const.SENTINEL_DEPTH_LIMIT
    }

    $Command = if ($PsCmdlet.ParameterSetName -eq 'Inferred') {
        $cmd = "Find-MyTree"
        $cmd += " -Subdirectory '$Subdirectory'"
        $cmd += " -Mode '$Mode'"
        $cmd += " -Tag '$Tag'"

        if ($DepthLimit -gt $const.SENTINEL_DEPTH_LIMIT) {
            $cmd += " -DepthLimit $DepthLimit"
        }

        $cmd
    } else {
        ""
    }

    $RotateProperties = $setting.RotateSubtreeOnProperties
    $IgnoreSubdirectory = $setting.IgnoreSubdirectory
    $path = Join-Path (Join-Path $Directory $Subdirectory) '*.md'

    $dir = $path `
        | Get-ChildItem `
            -Recurse `
        | where {
            $_.FullName -notlike "*$IgnoreSubdirectory*"
        }

    if ($Mode -in @('Cat', 'Edit', 'Start')) {
        if ($Command) {
            Write-Output $Command
            Write-Output ""
        }

        if ($null -eq $Tag) {
            switch ($Mode) {
                'Cat' {
                    return $dir | cat
                }

                default {
                    return
                    "Cannot run command indiscriminately on all files"
                }
            }
        }

        $grep = @()

        foreach ($subtag in $Tag) {
            $grep += @(
                $dir `
                    | Select-String "- tag\:.*$subtag"
            )

            $grep += @(
                $dir `
                    | Select-String "- tag\:\s*$" -Context 0, 99 `
                    | where {
                        $_.Context.PostContext `
                            -match "^\s*-\s*[^:]*$subtag[^:]*$"
                    }
            )
        }

        if ($grep.Count -eq 0) {
            return "No files found"
        }

        switch ($Mode) {
            'Cat' {
                return dir $grep.Path | cat
            }

            'Edit' {
                $setting =
                    cat "$PsScriptRoot\..\res\setting.json" `
                        | ConvertFrom-Json

                $EditCommand = $setting.EditCommand

                foreach ($item in $grep) {
                    Invoke-Expression `
                        "$EditCommand $($item.Path) +$($item.LineNumber)"
                }

                return $grep
            }

            'Start' {
                foreach ($item in $grep) {
                    Invoke-Expression `
                        "Start-Process $($item.Path)"
                }
            }
        }
    }

    $tree = $dir `
        | Get-Content `
        | Get-MarkdownTree `
            -DepthLimit $DepthLimit `
            -MuteProperty:$setting.MuteProperties

    if ($null -ne $Tag -and $Tag.Count -gt 0) {
        $tree = $tree `
            | Find-Subtree `
                -PropertyName tag `
            | where {
                $subtreeTags = $_.
                    tag.
                    ToLower().
                    Split(',').
                    Split(' ').
                    Trim() |
                    where { $_ }

                Find-Tag `
                    -Haystack $Tag.ToLower() `
                    -Needle $subtreeTags
            }
    }

    $tree = $tree | Get-SubtreeRotation `
        -RotateProperty $RotateProperties

    $tree = switch ($Mode) {
        'Tree' {
            $tree
        }

        'Print' {
            $tree | Write-MarkdownTree `
                -NoTables
        }
    }

    if ($Command) {
        return [PsCustomObject]@{
            Command = $Command
            Tree = $tree
        }
    }

    return $tree
}

# # todo
# - [ ] test
function Get-MySchedule {
    [CmdletBinding(DefaultParameterSetName = "Named")]
    Param(
        [Parameter(ParameterSetName = 'Named')]
        [ArgumentCompleter({
            Param(
                $cmdName,
                $paramName,
                $wordToComplete,
                $cmdAst,
                $preBoundParameters
            )

            $setting =
                cat "$PsScriptRoot\..\res\setting.json" `
                | ConvertFrom-Json

            $dirs = (dir $setting.ScheduleDirectory -Directory).Name

            $suggestions = if ($wordToComplete) {
                $dirs | where { $_ -like "$wordToComplete*" }
            }
            else {
                $dirs
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $dirs
            })
        })]
        [String]
        $Subdirectory,

        [Parameter(ParameterSetName = 'Named')]
        [ValidateSet('Schedule', 'Edit', 'Start', 'Cat', 'Tree')]
        [String]
        $Mode,

        [Parameter(ParameterSetName = 'Named')]
        [String[]]
        $Pattern,

        [Parameter(ParameterSetName = 'Named')]
        [Alias('Date')]
        [ArgumentCompleter({
            Param(
                $cmdName,
                $paramName,
                $wordToComplete,
                $cmdAst,
                $preBoundParameters
            )

            $date = Get-Date

            $dates = (@(0 .. 62) + @(-61 .. -1)) | foreach {
                Get-Date ($date.AddDays($_)) -Format 'yyyy_MM_dd'
            }

            $suggestions = if ($wordToComplete) {
                $dates | where { $_ -like "$wordToComplete*" }
            }
            else {
                $dirs
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $dates
            })
        })]
        [String[]]
        $StartDate,

        [Parameter(ParameterSetName = 'Named')]
        [String]
        $Directory,

        [Parameter(ParameterSetName = 'Named')]
        [String]
        $Extension,

        [Switch]
        $Week,

        [Switch]
        $NoConfirm,

        [Switch]
        $NoHints,

        [Parameter(
            ParameterSetName = 'Inferred',
            Position = 0
        )]
        [String[]]
        $Arguments

        # todo
        # - [ ] WhatIf
    )

    $setting =
        cat "$PsScriptRoot\..\res\setting.json" `
        | ConvertFrom-Json

    Set-Variable `
        -Option Constant `
        -Name 'const' `
        -Value @([PsCustomObject]@{
            DEFAULT_MODE = 'Schedule'
        })

    if ($PsCmdlet.ParameterSetName -eq 'Inferred') {
        $path = $setting.ScheduleDirectory
        $subdirectories = (dir $path -Directory).Name
        $validModes = @('Schedule', 'Edit', 'Start', 'Cat', 'Tree')
        $startDate_subitem = $null

        foreach ($arg in $Arguments) {
            if (-not $startDate_subitem `
                -and $arg -match "^\d{4}(_\d{2}){2}(_\d+)?$")
            {
                $startDate_subitem = $arg
            }
            elseif (-not $Mode `
                -and $arg -in $validModes)
            {
                $Mode = $arg
            }
            elseif (-not $Subdirectory `
                -and $arg -in $subdirectories)
            {
                $Subdirectory = $arg
            }
            elseif (-not $Extension `
                -and $arg -match '\.\w(\w|\d)*')
            {
                $Extension = $arg
            }
            elseif (-not $Pattern) {
                $Pattern = $arg
            }
        }
    }

    if (-not $Mode) {
        $Mode = $const.DEFAULT_MODE
    }

    if (-not $Directory) {
        $Directory = $setting.ScheduleDirectory
    }

    if (-not $Extension) {
        $Extension = $setting.ScheduleExtension
    }

    if ($PsCmdlet.ParameterSetName -eq 'Inferred') {
        $cmd = "Get-MySchedule"
        $cmd += " -Subdirectory '$Subdirectory'"
        $cmd += " -Mode '$Mode'"
        $cmd += " -Extension '$Extension'"

        if ($Pattern) {
            $cmd += " -Pattern '$Pattern'"
        }

        Write-Output $cmd
        Write-Output ""
    }

    function Get-NewDirectoryPath {
        Param(
            [String]
            $Directory,

            [String]
            $Subdirectory,

            [String]
            $DefaultSubdirectory,

            [String]
            $Extension
        )

        $path = if ($Subdirectory) {
            Join-Path $Directory $Subdirectory
        }
        elseif ($DefaultSubdirectory) {
            Join-Path $Directory $DefaultSubdirectory
        }
        else {
            $Directory
        }

        if ($Extension) {
            $path = Join-Path $path $Extension
        }

        return $path
    }

    function Get-ScheduleObject {
        Param(
            [Object[]]
            $File,

            [Object[]]
            $JsonFile,

            [String]
            $StartDate,

            [PsCustomObject]
            $Default,

            [String]
            $DefaultsFileName,

            [Switch]
            $NoHints
        )

        $IgnoreSubdirectory =
            (cat "$PsScriptRoot\..\res\setting.json" `
                | ConvertFrom-Json).IgnoreSubdirectory

        $schedule =
            Get-ChildItem `
                -Path $File `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Get-Content `
            | Get-Schedule `
                -StartDate:$StartDate `
                -Week:$Week `
                -Default:$Default

        if ($null -ne $JsonFile -and (Test-Path $JsonFile)) {
            $subtables =
                Get-ChildItem `
                    -Path $JsonFile `
                    -Recurse `
                | where {
                    $_.FullName -notlike "*$IgnoreSubdirectory*" `
                    -and `
                    $DefaultsFileName -ne $_.Name.ToLower()
                } | foreach {
                    cat $_ | ConvertFrom-Json
                }

            $schedule = $schedule `
                | Add-Schedule `
                    -Table $subtables `
                    -StartDate:$StartDate
        }

        return $schedule
    }

    . "$PsScriptRoot\ScheduleObject.ps1"

    $DefaultsFileName = $setting.ScheduleDefaultsFile
    $EditCommand = $setting.EditCommand
    $RotateProperties = $setting.RotateSubtreeOnProperties
    $IgnoreSubdirectory = $setting.IgnoreSubdirectory
    $DefaultSubdirectory = $setting.ScheduleDefaultSubdirectory

    $DefaultSubdirectory = switch ($Mode) {
        'Cat' { '' }
        'Edit' { '' }
        'Start' { '' }
        'Tree' { '' }
        'Schedule' { $DefaultSubdirectory }
    }

    $path = Get-NewDirectoryPath `
        -Directory $Directory `
        -Subdirectory $Subdirectory `
        -DefaultSubdirectory $DefaultSubdirectory

    if (-not (Test-Path $path)) {
        if (-not $NoHints) {
            Write-Output "Path not found"
            Write-Output "Hint: The Directory must be a schedule ""notebook"", with at least one subdirectory called ""$($setting.ScheduleDefaultSubdirectory)"""
        }

        return @()
    }

    $files = Join-Path $path $Extension
    $defaultsPath = Join-Path $path $DefaultsFileName

    $defaults = if ((Test-Path $defaultsPath)) {
        cat $defaultsPath | ConvertFrom-Json
    } else {
        $null
    }

    $jsonFiles = Join-Path $path "*.json"

    if ($null -ne $Pattern -and $Pattern.Count -gt 0) {
        $files = $Pattern | foreach {
            dir $files `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Select-String $_ `
            | sort -Property Path -Unique
        }

        $jsonFiles = $Pattern | foreach {
            dir $jsonFiles `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Select-String $_ `
            | sort -Property Path -Unique
        }

        if ($null -eq $files -and $null -eq $jsonFiles) {
            # Make the output look pretty
            $dir = $path | Get-Item
            Write-Output "No content in $($dir.FullName) could be found matching the pattern '$Pattern'"
        }
        elseif ($Mode -eq 'Edit') {
            foreach ($grep in (@($files) + @($jsonFiles))) {
                Invoke-Expression `
                    "$EditCommand $($grep.Path) +$($grep.LineNumber)"
            }

            Write-Output $files
            Write-Output $jsonFiles
            $files = $null
            $jsonFiles = $null
        }
        elseif ($Mode -eq 'Start') {
            foreach ($grep in (@($files) + @($jsonFiles))) {
                Invoke-Expression `
                    "Start-Process $($grep.Path)"
            }

            Write-Output $files
            Write-Output $jsonFiles
            $files = $null
            $jsonFiles = $null
        }
        else {
            if ($null -ne $files) {
                $files = $files.Path
            }

            if ($null -ne $jsonFiles) {
                $jsonFiles = $jsonFiles.Path
            }
        }
    }

    if ($Mode -in @('Edit', 'Start')) {
        $command = ""
        $nonConfirmMessage = ""
        $confirmMessage = ""

        switch ($Mode) {
            'Edit' {
                $command = $EditCommand
                $nonConfirmMessage = "Opening to editor"
                $confirmMessage = "open to editor"
            }

            'Start' {
                $command = "Start-Process"
                $nonConfirmMessage = "Starting"
                $confirmMessage = "start"
            }
        }

        $allDirs = (@($files) + @($jsonFiles)) | where { $null -ne $_ }

        if ($NoConfirm) {
            Write-Output "$nonConfirmMessage all files in"
            Write-Output "  $files"
            Write-Output "  $jsonFiles"
        }
        elseif ($null -ne $allDirs -and @($allDirs).Count -gt 1) {
            Write-Output "This will $confirmMessage all files in"
            Write-Output "  $files"
            Write-Output "  $jsonFiles"
            Write-Output ""
            $confirm = 'n'

            do {
                $confirm = Read-Host "Continue? (y/n)"
            }
            while ($confirm -notin @('n', 'y'))

            if ($confirm -eq 'n') {
                return
            }
        }

        foreach ($dir in $allDirs) {
            foreach ($item in (dir $dir)) {
                Invoke-Expression "$command $item"
            }
        }
    }
    elseif ($Mode -eq 'Cat') {
        if ($null -ne $files) {
            dir $files | cat
        }

        if ($null -ne $jsonFiles) {
            dir $jsonFiles | cat
        }
    }
    else {
        if (-not $StartDate) {
            $StartDate = Get-Date -f 'yyyy_MM_dd'
        }

        foreach ($startDate_subitem in $StartDate) {
            $schedule = Get-ScheduleObject `
                -File:$files `
                -JsonFile:$jsonFiles `
                -StartDate:$startDate_subitem `
                -Default:$defaults `
                -DefaultsFileName:$DefaultsFileName `
                -NoHints:$NoHints

            switch ($Mode) {
                'Schedule' {
                    # # OLD (karlr (2023_01_26_140650)
                    # # ------------------------------
                    # # link
                    # # - url: <https://stackoverflow.com/questions/24446680/is-it-possible-to-check-if-verbose-argument-was-given-in-powershell>
                    # # - retrieved: 2023_01_26
                    #
                    # $hasVerbose =
                    #     $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

                    # link
                    # - url: <https://www.briantist.com/how-to/test-for-verbose-in-powershell/>
                    # - retrieved: 2023_01_26
                    $hasVerbose =
                        $VerbosePreference `
                        -ne [System.Management.Automation.ActionPreference]::SilentlyContinue

                    $schedule | Write-Schedule `
                        -Verbose:$hasVerbose
                }

                'Tree' {
                    $schedule `
                        | Get-SubtreeRotation `
                            -RotateProperty $RotateProperties `
                        | Write-MarkdownTree `
                            -NoTables
                }
            }
        }
    }
}

