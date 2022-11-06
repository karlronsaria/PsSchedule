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
        $EPOCH_YEAR = 1970
        $LONG_TIME_DAYS_THRESHOLD = 10

        $day = $null
        $month = $null
        $year = $null
        $hostForeground =
            (Get-Host).Ui.RawUi.ForegroundColor

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

        $prevDate = Get-Date -Year $EPOCH_YEAR -Month 1 -Day 1
    }

    Process {
        if ($null -eq $ActionItem) {
            Write-OutputColored `
                -InPutObject '[Error: action item was found to be null]'

            return
        }

        $when = $ActionItem.when
        $isNewDay = $day -ne $when.Day `
            -or $month -ne $when.Month `
            -or $year -ne $when.Year

        if ($isNewDay) {
            $isLongComing = $EPOCH_YEAR -ne $prevDate.Year `
                -and $LONG_TIME_DAYS_THRESHOLD -le ($when - $prevDate).Days

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

        $icon = $null
        $foreground = $null
        $what = $ActionItem.what

        switch ($ActionItem.type) {
            'deadline' {
                $icon = '[!]'
                $foreground = 'Red'
            }

            'event' {
                $what = "event: $what"
                $foreground = 'Green'
            }

            default {
                $icon = '   '
                $foreground = $hostForeground
            }
        }

        $displayItem = [PsCustomObject]@{
            When = "$(Get-Date $when -f HH:mm)"
            Type = $icon
            What = $what
        }

        $str = $displayItem `
            | Format-Table -HideTableHeaders `
            | Out-String

        $str = $str.Trim()

        if (-not [String]::IsNullOrWhiteSpace($str)) {
            Write-OutputColored $str -Foreground $foreground
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
        $StartDate = $(Get-Date -f 'yyyy_MM_dd')
    )

    Begin {
        $content = @()
    }

    Process {
        if ($PsCmdlet.ParameterSetName -eq 'ByLine') {
            $content += @($Line)
        }
    }

    End {
        switch ($PsCmdlet.ParameterSetName) {
            'ByDirectory' {
                $what = @()

                if ( `
                    -not [String]::IsNullOrWhiteSpace($Subdirectory))
                {
                    $DirectoryPath =
                        Join-Path $DirectoryPath $Subdirectory
                }
                elseif ( `
                    -not [String]::IsNullOrWhiteSpace($DefaultSubdirectory))
                {
                    $DirectoryPath =
                        Join-Path $DirectoryPath $DefaultSubdirectory
                }

                $mdFiles = Join-Path $DirectoryPath "*.md"

                if (-not (Test-Path $mdFiles)) {
                    return $what
                }

                $defaultsPath =
                    Join-Path $DirectoryPath 'default.json' `

                $defaults = if ((Test-Path $defaultsPath)) {
                    cat $defaultsPath | ConvertFrom-Json
                } else {
                    $null
                }

                $what =
                    Get-ChildItem `
                        -Path $mdFiles `
                        -Recurse:$Recurse `
                    | Get-Content `
                    | Get-Schedule `
                        -StartDate:$StartDate `
                        -Default:$defaults

                $jsonFiles = Join-Path $DirectoryPath "*.json"

                if (-not (Test-Path $jsonFiles)) {
                    return $what
                }

                $subtables =
                    Get-ChildItem `
                        -Path $jsonFiles `
                        -Recurse:$Recurse `
                    | where {
                        'default.json' -ne $_.Name.ToLower()
                    } | foreach {
                        cat $_ | ConvertFrom-Json
                    }

                return $what `
                    | Add-Schedule `
                        -Table $subtables `
                        -StartDate:$StartDate
            }

            'ByLine' {
                $date = [DateTime]::ParseExact( `
                    $StartDate, `
                    'yyyy_MM_dd', `
                    $null `
                )

                $what = $content `
                    | Get-MarkdownTable

                return $what | foreach {
                    switch ($_) {
                        'Error' { $null }
                        default {
                            $temp = if ($null -eq $Default) {
                                $_.sched `
                                | Get-Schedule_FromTable `
                                    -StartDate $date
                            } else {
                                $_.sched `
                                | Get-Schedule_FromTable `
                                    -StartDate $date `
                                    -Default $Default
                            }

                            $temp `
                            | Sort-Object `
                                -Property when `
                            | Where-Object {
                                $date -lt $_.when
                            }
                        }
                    }
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
        $StartDate = $(Get-Date -f 'yyyy_MM_dd')
    )

    Begin {
        $list = @()
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

        return $list `
            + @($Table | Get-Schedule_FromTable `
                -StartDate $date
            ) `
            | Sort-Object `
                -Property when `
            | Where-Object {
                $date -lt $_.when
            }
    }
}

function Write-MarkdownTree {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Int]
        $Level = 0
    )

    Process {
        if ($null -eq $InputObject) {
            return
        }

        switch -Regex ($InputObject.GetType().Name) {
            '.*\[\]$' {
                foreach ($subitem in $InputObject) {
                    Write-MarkdownTree $subitem $Level
                }
            }

            'PsCustomObject' {
                $properties = $InputObject.PsObject.Properties `
                    | where {
                        'NoteProperty' -eq $_.MemberType
                    }

                foreach ($property in $properties) {
                    Write-Output "$('  ' * $Level)- $($property.Name)"
                    Write-MarkdownTree $property.Value ($Level + 1)
                }
            }

            default {
                Write-Output "$('  ' * $Level)- $InputObject"
            }
        }
    }
}

function Find-Subtree {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [String]
        $Name
    )

    Process {
        if ($null -eq $InputObject) {
            return @()
        }

        $subresults = @()

        switch -Regex ($InputObject.GetType().Name) {
            '.*\[\]$' {
                $i = 0

                while ($i -lt $InputObject.Count) {
                    $subresults += @((Find-Subtree $InputObject[$i] $Name))
                    $i = $i + 1
                }
            }

            'PsCustomObject' {
                $properties = $InputObject.PsObject.Properties `
                    | where {
                        'NoteProperty' -eq $_.MemberType
                    }

                if ($Name -in $properties.Name) {
                    $subresults += @($InputObject)
                }
                else {
                    foreach ($property in $properties) {
                        $subresults += @((Find-Subtree $property.Value $Name))
                    }
                }
            }
        }

        return $subresults
    }
}

function Get-MarkdownTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Line
    )

    Begin {
        $content = @()
    }

    Process {
        $content += @($Line)
    }

    End {
        $what = $content `
            | Get-MarkdownTable_FromCat `
            | Get-HighestLevel_FromTable

        $table = $what.Table `
            | Get-TableTrim `
                -StartLevel $what.StartLevel

        return $table `
            | Get-MarkdownTree_FromTable `
                -HighestLevel $what.HighestLevel
    }
}

function Get-MarkdownTable_FromCat {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Line
    )

    Begin {
        $prevType = 'None'
        $level = 0
        $indentLength = 0
    }

    Process {
        $capture = [Regex]::Match($Line, '^(?<indent>\s*)((?<header>#+)|(?<list_item_delim>\-|\*|\d+\.)\s)\s*(?<content>.+)$')
        $header = $capture.Groups['header']
        $indent = $capture.Groups['indent']

        $type = if ($capture.Groups['list_item_delim'].Success) {
            'ListItem'
        } elseif ($header.Success) {
            'Header'
        } else {
            'None'
        }

        if ('Header' -eq $type) {
            $level = $header.Length
        }

        if ('ListItem' -eq $type) {
            if ('Header' -eq $prevType) {
                $level = $level + 1
            }

            if ('ListItem' -eq $prevType -and $indent.Length -ne $indentLength) {
                $level += ($indent.Length - $indentLength) / 2
            }
        }

        $indentLength = $indent.Length

        if ('None' -ne $type) {
            $prevType = $type
        }

        [PsCustomObject]@{
            Level = $level
            Type = $type
            Content = $capture.Groups['content'].Value
        }
    }
}

function Get-HighestLevel_FromTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $TableRow
    )

    Begin {
        $startLevel = $null
        $highestLevel = $null
        $table = @()
    }

    Process {
        if ($null -eq $startLevel) {
            $highestLevel = $startLevel = $TableRow.Level
        }

        if ($TableRow.Level -gt $highestLevel) {
            $highestLevel = $TableRow.Level
        }

        $table += @($TableRow)
    }

    End {
        return [PsCustomObject]@{
            StartLevel = $startLevel
            HighestLevel = $highestLevel
            Table = $table
        }
    }
}

function Get-TableTrim {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $TableRow,

        [Int]
        $StartLevel
    )

    Process {
        if ('None' -eq $TableRow.Type) {
            return
        }

        return [PsCustomObject]@{
            Level = $TableRow.Level - $StartLevel + 1
            Content = $TableRow.Content
        }
    }
}

function Get-MarkdownTree_FromTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $TableRow,

        [Int]
        $HighestLevel
    )

    Begin {
        $stack = @($null) * ($HighestLevel + 1)
        $stack[0] = [PsCustomObject]@{}
    }

    Process {
        $level = $TableRow.Level
        $content = $TableRow.Content
        $parent = $stack[$level - 1]

        if ($null -eq $parent) {
            return 'Error'
        }

        $capture = [Regex]::Match( `
            $content, `
            "^\s*(?<key>[^:`"]+)\s*:(\s+(?<value>.*))?\s*$" `
        )

        $key = $capture.Groups['key']

        if ($key.Success) {
            $content = $key.Value
            $stack[$level] = $capture.Groups['value'].Value
        } else {
            $stack[$level] = [PsCustomObject]@{}
        }

        $property = $parent.PsObject.Properties | where {
            $_.Name -eq $content
        }

        if ($null -ne $property) {
            if (1 -eq @($property.Value).Count) {
                $property.Value = @($property.Value)
            }

            $property.Value += @($stack[$level])
        }
        else {
            $parent | Add-Member `
                -MemberType NoteProperty `
                -Name $content `
                -Value $stack[$level]
        }
    }

    End {
        return $stack[0]
    }
}

function Get-Schedule_FromTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $InputObject,

        [DateTime]
        $StartDate = $(Get-Date),

        [PsCustomObject]
        $Default = ([PsCustomObject]@{
            when = (Get-Date -f HHmm)
            type = 'todayonly'
            every = 'none'
        })
    )

    Begin {
        function Get-WeekDayCode {
            Param(
                [DateTime]
                $Date
            )

            return $Date.DayOfWeek.ToString().Substring(0, 3).ToLower()
        }

        function Get-NewActionItem {
            Param(
                [PsCustomObject]
                $ActionItem,

                [DateTime]
                $Date
            )

            $what = [PsCustomObject]@{
                when = $Date
            }

            $properties = $ActionItem.PsObject.Properties | where {
                'NoteProperty' -eq $_.MemberType -and `
                @('when', 'every') -notcontains $_.Name.ToLower()
            }

            foreach ($property in $properties) {
                $what | Add-Member `
                    -MemberType NoteProperty `
                    -Name $property.Name.ToLower() `
                    -Value $property.Value
            }

            return $what
        }

        function Test-ActionItemIsOneDayEvent {
            Param(
                [PsCustomObject]
                $ActionItem,

                [PsCustomObject]
                $Default
            )

            $every = $ActionItem.every.ToLower()
            $when = $ActionItem.when.ToLower()
            $type = $ActionItem.type.ToLower()

            return @('event', 'errand', 'deadline') `
                    -contains $type `
                -and $when -match '\d{4}_\d{2}_\d{2}(_\{4})?'
        }

        function Test-ActionItemIsTodayOnly {
            Param(
                [PsCustomObject]
                $ActionItem
            )

            return @('todayonly', 'today-only', 'today only') `
                    -contains $ActionItem.type.ToLower()
        }

        function Get-DateParseVaryingLength {
            Param(
                [String]
                $DateString
            )

            $capture = [Regex]::Match( `
                $DateString, `
                "((?<day>\w{3})-)?(?<time>\d{4})?" `
            )

            $result = [PsCustomObject]@{
                Day = ''
                Time = ''
                DateTime = $null
            }

            if ($capture.Success) {
                $result.Day = $capture.Groups['day'].Value
                $result.Time = $capture.Groups['time'].Value
                $result.DateTime = $null
            }

            $pattern = switch -Regex ($DateString.Trim()) {
                '^\d{4}_\d{2}_\d{2}_\d{6}$' { 'yyyy_MM_dd_HHmmss'; break }
                '^\d{4}_\d{2}_\d{2}_\d{4}$' { 'yyyy_MM_dd_HHmm'; break }
                '^\d{4}_\d{2}_\d{2}_\d{2}$' { 'yyyy_MM_dd_HH'; break }
                '^\d{4}_\d{2}_\d{2}$' { 'yyyy_MM_dd'; break }
                '^\d{4}$' { 'HHmm'; break }
                default { ''; break }
            }

            if ([String]::IsNullOrEmpty($pattern)) {
                return $result
            }

            $result.DateTime = [DateTime]::ParseExact( `
                $DateString, `
                $pattern, `
                $null `
            )

            return $result
        }

        function Get-NoteProperty {
            Param(
                [PsCustomObject]
                $InputObject,

                [String]
                $PropertyName,

                $Default
            )

            $properties = $InputObject.PsObject.Properties `
                | where { 'NoteProperty' -eq $_.MemberType }

            if ([String]::IsNullOrEmpty($PropertyName)) {
                return $properties
            }

            $result = if ($PropertyName -in $properties.Name) {
                [PsCustomObject]@{
                    Success = $true
                    Name = $PropertyName
                    Value = $InputObject.$PropertyName
                }
            } else {
                [PsCustomObject]@{
                    Success = $false
                    Name = $PropertyName
                    Value = $Default.$PropertyName
                }
            }

            return $result
        }

        function Add-NoteProperty {
            Param(
                [PsCustomObject]
                $InputObject,

                [String]
                $PropertyName,

                $Default
            )

            $result = Get-NoteProperty `
                -InputObject $InputObject `
                -PropertyName $PropertyName `
                -Default $Default

            if ($result.Success) {
                return $result.Value
            }

            $InputObject | Add-Member `
                -MemberType 'NoteProperty' `
                -Name $result.Name `
                -Value $result.Value `

            return $result.Value
        }

        function Test-DateIsToday {
            Param(
                [DateTime]
                $Date
            )

            $now = Get-Date

            return $now.Year -eq $Date.Year `
                -and $now.Month -eq $Date.Month `
                -and $now.Day -eq $Date.Day

            return $list
        }
    }

    Process {
        $list = @()

        if ($null -eq $InputObject) {
            return $list
        }

        $schedWhen = Add-NoteProperty `
            -InputObject $InputObject `
            -PropertyName 'when' `
            -Default $Default

        if ($schedWhen -is [String]) {
            $schedWhen = $schedWhen.ToLower()
        }
        else {
            foreach ($property in (Get-NoteProperty $schedWhen)) {
                $obj = $InputObject.PsObject.Copy()
                $obj.when = "$($property.Name)"

                $what = Get-Schedule_FromTable `
                    -InputObject $obj `
                    -StartDate:$StartDate `
                    -Default:$Default

                $list += @($what)
            }

            return $list
        }

        $schedType = (Add-NoteProperty `
            -InputObject $InputObject `
            -PropertyName 'type' `
            -Default $Default).ToLower()

        if ('todo' -eq $schedType) {
            $capture =
                [Regex]::Match($schedWhen, '\s*\[ \]\s+(?<datetime>.*)$')

            if (-not $capture.Success) {
                return $list
            }

            $schedWhen = $capture.Groups['datetime'].Value

            $InputObject | Add-Member `
                -MemberType NoteProperty `
                -Name complete `
                -Value $false
        }

        $schedEvery = (Add-NoteProperty `
            -InputObject $InputObject `
            -PropertyName 'every' `
            -Default $Default).ToLower()

        $todayOnlyEvent = Test-ActionItemIsTodayOnly `
            -ActionItem $InputObject

        $oneDayEvent = Test-ActionItemIsOneDayEvent `
            -ActionItem $InputObject `
            -Default $Default

        $dateTimeResult = Get-DateParseVaryingLength `
            -DateString $schedWhen

        $schedDay = $dateTimeResult.Day
        $schedTime = $dateTimeResult.Time
        $date = Get-Date

        switch -Regex ($schedEvery) {
            'none' {
                $date = $dateTimeResult.DateTime

                if ($todayOnlyEvent) {
                    if ((Test-DateIsToday -Date $date)) {
                        $what = Get-NewActionItem `
                            -ActionItem $InputObject `
                            -Date $date

                        $list += @($what)
                    }

                    return $list
                }

                if ($oneDayEvent) {
                    $what = Get-NewActionItem `
                        -ActionItem $InputObject `
                        -Date $date

                    $list += @($what)
                    return $list
                }

                break
            }

            'day' {
                $invalid =
                    [String]::IsNullOrWhiteSpace($schedTime)

                if ($invalid) {
                    return
                }

                break
            }

            'week' {
                $invalid =
                        [String]::IsNullOrWhiteSpace($schedDay) `
                    -or [String]::IsNullOrWhiteSpace($schedTime)

                if ($invalid) {
                    return
                }

                $date = $StartDate

                while ($schedDay.ToLower() -ne (Get-WeekDayCode -Date $date)) {
                    $date = $date.AddDays(1)
                }

                break
            }

            '\w+(\s*,\s*\w+)*' {
                $invalid =
                    [String]::IsNullOrWhiteSpace($schedTime)

                $days = $schedEvery -Split '\s*,\s*'

                $days = $days | where {
                    @('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun') `
                        -contains $_
                } | select -Unique

                foreach ($day in $days) {
                    $obj = $InputObject.PsObject.Copy()
                    $obj.every = 'week'
                    $obj.when = "$day-$schedTime"

                    $what = Get-Schedule_FromTable `
                        -InputObject $obj `
                        -StartDate:$StartDate `
                        -Default:$Default

                    $list += @($what)
                }

                return $list
            }
        }

        $time = [DateTime]::ParseExact($schedTime, 'HHmm', $null)

        $dateTime = Get-Date `
            -Year $date.Year `
            -Month $date.Month `
            -Day $date.Day `
            -Hour $time.Hour `
            -Minute $time.Minute `
            -Second 0

        $isToday =
            Test-DateIsToday -Date $dateTime

        $addTodo =
            'todo' -eq $InputObject.type `
                -and -not $InputObject.complete `
                -and $StartDate -gt $dateTime

        $addToday =
            ($todayOnlyEvent `
                -and $isToday) `
            -or `
                $addTodo `
            -or `
            (-not $todayOnlyEvent `
                -and 'todo' -ne $InputObject.type)

        if ($addTodo) {
            $dateTime = $StartDate.AddMinutes(1)
        }

        if ($addToday) {
            $what = Get-NewActionItem `
                -ActionItem $InputObject `
                -Date $dateTime

            $list += @($what)
        }

        return $list
    }
}

