# . "$PsScriptRoot/MarkdownObject.ps1"
# . "$PsScriptRoot/ScheduleFromTable.ps1"

<#
.EXAMPLE
cat .\sched\*.md | Get-Schedule -StartDate 2022_10_11 | Write-Schedule
#>
function Write-Schedule {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $ActionItem
    )

    Begin {
        Set-Variable `
            -Option Constant `
            -Name 'const' `
            -Value @([PsCustomObject]@{
                EPOCH_YEAR = 1970
                LONG_TIME_DAYS_THRESHOLD = 10
                ITEM_CONTINUATION_SYMBOL = '---'
            })

        $day = $null
        $month = $null
        $year = $null
        $hostForeground =
            (Get-Host).Ui.RawUi.ForegroundColor

        function Write-ActionItem {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                $ActionItem
            )

            $icon = $null
            $foreground = $null
            $what = $ActionItem.what

            # # frivolous
            # $emoji = $([System.Char]::ConvertFromUtf32([System.Convert]::ToInt32("1F600", 16))]

            $icon = '   '
            $foreground = $hostForeground

            $actionable = ($ActionItem | Get-NoteProperty `
                -PropertyName 'complete').Success

            $addendum = ($ActionItem | Get-NoteProperty `
                -PropertyName 'Addendum').Success

            if ($addendum) {
                $what = "$($ActionItem.Addendum): $what"
            }

            if ($actionable) {
                $icon = if ($ActionItem.complete) {
                    '[x]'
                } else {
                    '[ ]'
                }

                $what = "todo: $what"
                $foreground = 'Yellow'
            }

            # rule
            # - types 'todo', 'deadline', and 'event' must be mutually exclusive
            # - type 'overlap' must follow these types when used
            foreach ($type in $ActionItem.type.Split(',').Trim()) {
                switch ($type) {
                    'todo' {
                        if (-not $actionable) {
                            $what = "todo: $what"
                            $icon = '[ ]'
                            $foreground = 'Yellow'
                        }
                    }

                    'deadline' {
                        $icon = '[!]'
                        $foreground = 'Red'
                    }

                    'event' {
                        $what = "event: $what"
                        $foreground = 'Green'
                    }

                    'overlap' {
                        $what = "overlap: $what"
                        $foreground = 'Magenta'
                    }
                }
            }

            $displayItem = [PsCustomObject]@{
                When = "$(Get-Date $ActionItem.when -f HH:mm)"
                Type = $icon
                What = "⟐ $what"
            }

            $displayItems = @($displayItem)

            if ($ActionItem.PsObject.Properties.Name -contains 'to') {
                $hour = $null
                $minute = $null
                $to = $ActionItem.to

                switch ($to) {
                    { $to -is [String] } {
                        $hour = $to.Substring(0, 2)
                        $minute = $to.Substring(2)
                    }

                    { $to -is [DateTime] } {
                        $hour = $to.Hour
                        $minute = $to.Minute
                    }
                }

                $displayItems +=
                    @([PsCustomObject]@{
                        When =
                            "$(Get-Date -Hour $hour -Minute $minute -f HH:mm)"
                        Type = $icon
                        What = $const.ITEM_CONTINUATION_SYMBOL
                    })
            }

            foreach ($displayItem in $displayItems) {
                $str = $displayItem `
                    | Format-Table `
                        -Property `
                            When, `
                            @{
                                Name = 'Type'
                                Expression = { $_.Type }
                                Align = 'Right'
                            }, `
                            What `
                        -HideTableHeaders `
                    | Out-String

                $str = $str.Trim()

                if (-not [String]::IsNullOrWhiteSpace($str)) {
                    Write-OutputColored $str -Foreground $foreground
                }
            }
        }

        function Write-OutputColored {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                $Foreground
            )

            $hf = $host.Ui.RawUi.ForegroundColor

            if ($null -ne $Foreground) {
                $host.Ui.RawUi.ForegroundColor = $Foreground
            }

            if ($InputObject) {
                Write-Output $InputObject
            }
            else {
                Write-Output ''
            }

            $host.Ui.RawUi.ForegroundColor = $hf
        }

        $prevDate = Get-Date -Year $const.EPOCH_YEAR -Month 1 -Day 1
    }

    Process {
        if ($null -eq $ActionItem) {
            Write-OutputColored `
                -InputObject '[Error: action item was found to be null]'

            return
        }

        $when = $ActionItem.when

        $isNewDay = $day -ne $when.Day `
            -or $month -ne $when.Month `
            -or $year -ne $when.Year

        if ($isNewDay) {
            $isLongComing = $const.EPOCH_YEAR -ne $prevDate.Year `
                -and $const.LONG_TIME_DAYS_THRESHOLD `
                -le ($when - $prevDate).Days

            $prevDate = $when

            if ($isLongComing) {
                Write-OutputColored `
                    -InputObject "`r`n     . . .`r`n" `
                    -Foreground DarkGray
            }

            $day = $when.Day
            $month = $when.Month
            $year = $when.Year
            $heading = "$($when.DayOfWeek) ($(Get-Date $when -f yyyy_MM_dd))"

            Write-OutputColored
            Write-OutputColored $heading `
                -Foreground DarkGray
            Write-OutputColored "$("-" * $heading.Length)" `
                -Foreground DarkGray
        }

        $ActionItem | Write-ActionItem

        $subtree = $ActionItem | Find-Subtree `
            -PropertyName 'complete' `
            -Parent $ActionItem.what

        # # OLD (karlr (2023_01_26_140650)
        # # ------------------------------
        # # link
        # # - url: https://stackoverflow.com/questions/24446680/is-it-possible-to-check-if-verbose-argument-was-given-in-powershell
        # # - retrieved: 2023_01_26
        #
        # $hasVerbose =
        #     $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

        # link
        # - url: https://www.briantist.com/how-to/test-for-verbose-in-powershell/
        # - retrieved: 2023_01_26
        $hasVerbose =
            $VerbosePreference `
            -ne [System.Management.Automation.ActionPreference]::SilentlyContinue

        if ($hasVerbose -and $null -ne $subtree) {
            Write-OutputColored

            $subtree | foreach {
                if (-not $_.child.complete) {
                    [PsCustomObject]@{ $_.parent = $_.child } `
                        | Write-MarkdownTree
                }
            }

            Write-OutputColored
        }
    }

    End {
        Write-OutputColored
    }
}

<#
.EXAMPLE
cat .\sched\*.md | Get-Schedule
#>
function Get-Schedule {
    [CmdletBinding(DefaultParameterSetName = 'ByLine')]
    Param(
        [Parameter(
            ParameterSetName = 'ByLine',
            ValueFromPipeline = $true
        )]
        [String]
        $Line,

        [Parameter(
            ParameterSetName = 'ByLine'
        )]
        [PsCustomObject]
        $Default,

        [Parameter(
            ParameterSetName = 'ByDirectory'
        )]
        [String]
        $DirectoryPath,

        [Parameter(
            ParameterSetName = 'ByDirectory'
        )]
        [String]
        $Subdirectory,

        [Parameter(
            ParameterSetName = 'ByDirectory'
        )]
        [String]
        $DefaultSubdirectory,

        [Parameter(
            ParameterSetName = 'ByDirectory'
        )]
        [Switch]
        $Recurse,

        [String]
        $StartDate,

        [Switch]
        $Week
    )

    Begin {
        $content = @()

        if (-not $StartDate) {
            $StartDate = Get-Date -f 'yyyy_MM_dd'
        }
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq 'ByLine') {
            $content += @($Line)
        }
    }

    End {
        $setting = cat "$PsScriptRoot\..\res\setting.json" `
            | ConvertFrom-Json

        switch ($PsCmdlet.ParameterSetName) {
            'ByDirectory' {
                $DirectoryPath =
                    if (-not [String]::IsNullOrWhiteSpace( `
                        $Subdirectory `
                    )) {
                        Join-Path $DirectoryPath $Subdirectory
                    }
                    elseif (-not [String]::IsNullOrWhiteSpace( `
                        $DefaultSubdirectory `
                    )) {
                        Join-Path $DirectoryPath $DefaultSubdirectory
                    }
                    else {
                        $DirectoryPath
                    }

                if (-not (Test-Path $DirectoryPath)) {
                    return @()
                }

                $defaultsPath = Join-Path `
                    $DirectoryPath `
                    $setting.ScheduleDefaultsFile

                $defaults = if ((Test-Path $defaultsPath)) {
                    Get-Content $defaultsPath | ConvertFrom-Json
                } else {
                    $null
                }

                $mdFiles = Join-Path $DirectoryPath "*.md"
                $jsonFiles = Join-Path $DirectoryPath "*.json"

                $what = Get-ChildItem `
                        -Path $mdFiles `
                        -Recurse:$Recurse `
                    | Get-Content `
                    | Get-Schedule `
                        -StartDate:$StartDate `
                        -Default:$defaults

                    if (-not (Test-Path $jsonFiles)) {
                        return $what
                    }

                return Get-ChildItem `
                        -Path $jsonFiles `
                        -Recurse:$Recurse `
                    | where {
                        $setting.ScheduleDefaultsFile `
                            -ne $_.Name.ToLower()
                    } `
                    | Get-Content `
                    | ConvertFrom-Json `
                    | Add-Schedule `
                        -Table $what `
                        -StartDate:$StartDate
            }

            'ByLine' {
                $date = [DateTime]::ParseExact( `
                    $StartDate, `
                    'yyyy_MM_dd', `
                    $null `
                )

                $endDate = if ($Week) {
                    $date.AddDays(7)
                } else {
                    $null
                }

                return $content `
                    | Get-MarkdownTree `
                        -MuteProperty:$setting.MuteProperties `
                    | where {
                        $_ -ne 'Error'
                    } | foreach {
                        $_.sched
                    } | foreach {
                        $temp = $_
                        $properties = $temp.PsObject.Properties.Name

                        if ($properties -contains 'what') {
                            $temp
                        }
                        else {
                            foreach ($name in $properties) {
                                $newObject = $temp.$name

                                $newObject | Add-Member `
                                    -Name 'what' `
                                    -Value $name `
                                    -MemberType 'NoteProperty'

                                $newObject
                            }
                        }
                    } | Get-Schedule_FromTable `
                        -StartDate $date `
                        -EndDate:$endDate `
                        -Default:$Default `
                    | where {
                        $date -le $_.when
                    }
            }
        }
    }
}

<#
.EXAMPLE
cat .\sched\*.md | Get-Schedule | Add-Schedule -Table (ConvertFrom-Json .\sched\*.json)
#>
function Add-Schedule {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject[]]
        $InputObject,

        [PsCustomObject[]]
        $Table,

        [String]
        $StartDate,

        [Switch]
        $Week
    )

    Begin {
        $list = @()

        if (-not $StartDate) {
            $StartDate = $(Get-Date -f 'yyyy_MM_dd')
        }
    }

    Process {
        $list += @($InputObject)
    }

    End {
        $date = [DateTime]::ParseExact( `
            $StartDate, `
            'yyyy_MM_dd', `
            $null `
        )

        $endDate = if ($Week) {
            $date.AddDays(7)
        } else {
            $null
        }

        return $list `
            + @($Table | Get-Schedule_FromTable `
                -StartDate $date `
                -EndDate:$endDate
            ) `
            | Sort-Object `
                -Property when `
            | Where-Object {
                $date -le $_.when
            }
    }
}

