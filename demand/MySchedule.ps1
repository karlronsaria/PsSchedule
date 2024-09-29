class ScheduleStore {
    [String[]] $File
    [String[]] $Json
    [PsCustomObject[]] $Default

    ScheduleStore([String] $Path, [String] $Extension, [String] $DefaultsName) {
        $this.File = Join-Path $Path $Extension
        $defaultsPath = Join-Path $Path $DefaultsName

        $this.Default = if ((Test-Path $defaultsPath)) {
            cat $defaultsPath | ConvertFrom-Json
        } else {
            $null
        }

        $this.Json = Join-Path $path "*.json"
    }
}

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
        [ValidateSet('Print', 'Tree', 'Cat', 'Link', 'Edit', 'Start')]
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
        $validModes = @('Print', 'Tree', 'Cat', 'Link', 'Edit', 'Start')

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

    if ($Mode -in @('Cat', 'Link', 'Edit', 'Start')) {
        if ($Command) {
            Write-Output $Command
            Write-Output ""
        }

        if ($null -eq $Tag) {
            switch ($Mode) {
                'Link' {
                    return $dir
                }

                'Cat' {
                    return $dir | cat
                }

                default {
                    return "Cannot run command indiscriminately on all files"
                }
            }
        }

        $grep = @()

        foreach ($subtag in $Tag) {
            $grep += @(
                $dir |
                    Select-String "- tag\:.*$subtag"
            ) + @(
                $dir |
                    Select-String "- tag\:\s*$" -Context 0, 99 |
                    where {
                        $_.Context.PostContext `
                            -match "^\s*-\s*[^:]*$subtag[^:]*$"
                    }
            )
        }

        if ($grep.Count -eq 0) {
            return "No files found"
        }

        switch ($Mode) {
            'Link' {
                return dir $grep.Path
            }

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

            $dirs = (dir $setting.ScheduleDirectory -Directory).Name `
                + @('All')

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
        [String[]]
        $Subdirectory,

        [Parameter(ParameterSetName = 'Named')]
        [ValidateSet('Schedule', 'Link', 'Edit', 'Start', 'Cat', 'Tree', 'Table')]
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
        $validModes = @('Schedule', 'Link', 'Edit', 'Start', 'Cat', 'Tree')
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
            [Parameter(ValueFromPipeline = $true)]
            [ScheduleStore]
            $InputObject,

            [String]
            $StartDate,

            [String]
            $DefaultsFileName,

            [Switch]
            $NoHints
        )

        Begin {
            $IgnoreSubdirectory =
                (cat "$PsScriptRoot\..\res\setting.json" |
                    ConvertFrom-Json).IgnoreSubdirectory
        }

        Process {
            $schedule =
                Get-ChildItem `
                    -Path $InputObject.File `
                    -Recurse |
                where {
                    $_.FullName -notlike "*$IgnoreSubdirectory*"
                } |
                Get-Content |
                Get-Schedule `
                    -StartDate:$StartDate `
                    -Week:$Week `
                    -Default:$InputObject.Default

            if ($null -ne $InputObject.Json -and (Test-Path $InputObject.Json)) {
                $subtables =
                    Get-ChildItem `
                        -Path $InputObject.Json `
                        -Recurse |
                    where {
                        $_.FullName -notlike "*$IgnoreSubdirectory*" `
                        -and `
                        $DefaultsFileName -ne $_.Name.ToLower()
                    } |
                    foreach {
                        cat $_ | ConvertFrom-Json
                    }

                $schedule = $schedule |
                    Add-Schedule `
                        -Table $subtables `
                        -StartDate:$StartDate
            }

            return $schedule
        }
    }

    . "$PsScriptRoot\ScheduleObject.ps1"

    $DefaultsFileName = $setting.ScheduleDefaultsFile
    $EditCommand = $setting.EditCommand
    $RotateProperties = $setting.RotateSubtreeOnProperties
    $IgnoreSubdirectory = $setting.IgnoreSubdirectory

    $DefaultSubdirectory = switch ($Mode) {
        'Cat' { '' }
        'Link' { '' }
        'Edit' { '' }
        'Start' { '' }
        'Tree' { '' }
        'Schedule' { $setting.ScheduleDefaultSubdirectory }
    }

    if ($null -eq $Subdirectory -or @($Subdirectory).Count -eq 0) {
        $Subdirectory = $DefaultSubdirectory
    }

    if (($Subdirectory | where { $_ } | foreach { $_.ToLower() }) -contains 'all') {
        $Subdirectory = (dir $Directory -Directory).Name
    }

    $path =
        $Subdirectory |
        select -Unique |
        foreach {
            Get-NewDirectoryPath `
                -Directory $Directory `
                -Subdirectory $_ `
                -DefaultSubdirectory $DefaultSubdirectory
        }

    $stores =
        $path |
        foreach {
            if (-not (Test-Path $_)) {
                if (-not $NoHints) {
                    Write-Output "Path not found"
                    Write-Output "Hint: The Directory must be a schedule ""notebook"", with at least one subdirectory called ""$($setting.ScheduleDefaultSubdirectory)"""
                }
            }
            else {
                [ScheduleStore]::new($_, $Extension, $DefaultsFileName)
            }
        }

    foreach ($store in $stores) {
        if ($null -ne $Pattern -and $Pattern.Count -gt 0) {
            $fileGrep = $Pattern |
                foreach {
                    dir $store.File `
                        -Recurse |
                    where {
                        $_.FullName -notlike "*$IgnoreSubdirectory*"
                    } |
                    sls $_ |
                    sort `
                        -Property Path `
                        -Unique
                }

            $jsonGrep = $Pattern |
                foreach {
                    dir $store.Json `
                        -Recurse |
                    where {
                        $_.FullName -notlike "*$IgnoreSubdirectory*"
                    } |
                    sls $_ |
                    sort `
                        -Property Path `
                        -Unique
                }

            if ($null -eq $fileGrep -and $null -eq $jsonGrep) {
                # Make the output look pretty
                $dir = $path | Get-Item
                Write-Output "No content in $($dir.FullName) could be found matching the pattern '$Pattern'"
                $store.File = $null
                $store.Json = $null
            }
            elseif ($Mode -eq 'Link') {
                Write-Output $fileGrep.Path
                Write-Output $jsonGrep.Path
                $store.File = $null
                $store.Json = $null
            }
            elseif ($Mode -eq 'Edit') {
                foreach ($grep in (@($fileGrep) + @($jsonGrep))) {
                    Invoke-Expression `
                        "$EditCommand $($grep.Path) +$($grep.LineNumber)"
                }

                Write-Output $fileGrep
                Write-Output $jsonGrep
                $store.File = $null
                $store.Json = $null
            }
            elseif ($Mode -eq 'Start') {
                foreach ($grep in (@($fileGrep) + @($jsonGrep))) {
                    Invoke-Expression `
                        "Start-Process $($grep.Path)"
                }

                Write-Output $fileGrep
                Write-Output $jsonGrep
                $store.File = $null
                $store.Json = $null
            }
            else {
                if ($null -ne $fileGrep) {
                    $store.File = $fileGrep.Path
                }

                if ($null -ne $jsonGrep) {
                    $store.Json = $jsonGrep.Path
                }
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

        $allDirs = (@($stores.File) + @($stores.Json)) | where { $null -ne $_ }

        if ($NoConfirm) {
            Write-Output "$nonConfirmMessage all files in"
            Write-Output "  $($stores.File)"
            Write-Output "  $($stores.Json)"
        }
        elseif ($null -ne $allDirs -and @($allDirs).Count -gt 1) {
            Write-Output "This will $confirmMessage all files in"
            Write-Output "  $($stores.File)"
            Write-Output "  $($stores.Json)"
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
    elseif ($Mode -eq 'Link') {
        if ($null -ne $stores.File) {
            $stores.File | dir
        }

        if ($null -ne $stores.Json) {
            $stores.Json | dir
        }
    }
    elseif ($Mode -eq 'Cat') {
        if ($null -ne $stores.File) {
            dir $stores.File | cat
        }

        if ($null -ne $stores.Json) {
            dir $stores.Json | cat
        }
    }
    else {
        if (-not $StartDate) {
            $StartDate = Get-Date -f 'yyyy_MM_dd'
        }

        $schedule = foreach ($startDate_subitem in $StartDate) {
            $stores |
            Get-ScheduleObject `
                -StartDate:$startDate_subitem `
                -DefaultsFileName:$DefaultsFileName `
                -NoHints:$NoHints |
            sort -Property 'when'
        }

        switch ($Mode) {
            'Table' {
                $schedule
            }

            'Schedule' {
                # # OLD (karlr 2023_01_26_140650)
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

<#
.EXAMPLE
Get-MySchedule -Subdirectory All -Mode Table | Get-AvailableSchedule | Write-Schedule
#>
function Get-AvailableSchedule {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    Begin {
        $row = $null
        $prevTo = $null
        $type = 'routine'
        $what = 'available'
    }

    Process {
        if ($InputObject.PsObject.Properties.Name -notcontains 'to') {
            return
        }

        if ($null -eq $row) {
            $row = [PsCustomObject]@{
                when = (Get-Date $InputObject.when).Date
                to = $null
                type = $type
                what = $what
            }
        }
        else {
            $row = [PsCustomObject]@{
                when = $prevTo
                to = $null
                type = $type
                what = $what
            }
        }

        $row.to = $InputObject.when

        if ($row.to -gt $row.when) {
            $row
        }

        $result = Get-DateParseVaryingLength -DateString $InputObject.to

        $when = if ($result.DateTime) {
            $result.DateTime
        }
        elseif ($result.Time) {
            $temp = [DateTime]::ParseExact($result.Time, "HHmm", $null)
            $temp
        }

        $prevTo = Get-Date `
            -Year $InputObject.when.Year `
            -Month $InputObject.when.Month `
            -Day $InputObject.when.Day `
            -Hour $when.Hour `
            -Minute $when.Minute
    }

    End {
        if ($null -eq $prevTo) {
            return
        }

        [PsCustomObject]@{
            when = $prevTo
            to = (Get-Date $prevTo).Date.AddDays(1)
            type = $type
            what = $what
        }
    }
}

