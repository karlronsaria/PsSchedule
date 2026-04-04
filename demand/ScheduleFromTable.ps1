. "$PsScriptRoot\ScheduleObject.ps1"
. "$PsScriptRoot\ScheduleDateTime.ps1"

<#
.SYNOPSIS
f: (...) -> (...)
#>
function Get-Schedule_FromTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
        $InputObject,

        [DateTime]
        $StartDate = $(Get-Date),

        [Nullable[DateTime]]
        $EndDate,

        [PsCustomObject]
        $Default
    )

    Begin {
        function Get-NewActionItem {
            [CmdletBinding(DefaultParameterSetName = 'ByProperty')]
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [PsCustomObject]
                $ActionItem,

                [Parameter(ParameterSetName = 'ByDate')]
                [DateTime]
                $Date,

                [Parameter(ParameterSetName = 'ByProperty')]
                [String]
                $ExcludeProperty,

                [Parameter(ParameterSetName = 'ByProperty')]
                [Object[]]
                $AddProperty
            )

            $what = [PsCustomObject]@{}

            switch ($PsCmdlet.ParameterSetName) {
                'ByDate' {
                    $what = [PsCustomObject]@{
                        when = $Date
                    }

                    $properties = $ActionItem.PsObject.Properties | where {
                        'NoteProperty' -eq $_.MemberType -and `
                        @('when', 'every') -notcontains $_.Name.ToLower()
                    }
                }

                'ByProperty' {
                    $properties = $ActionItem.PsObject.Properties | where {
                        'NoteProperty' -eq $_.MemberType -and `
                        $_.Name.ToLower() -ne $ExcludeProperty.ToLower()
                    }

                    $properties = @($properties) + @($AddProperty)
                }
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

            $when, $type = 'when', 'type' |
                foreach {
                    $ActionItem.$_
                } |
                foreach {
                    if ($null -eq $_) {
                        $null
                    } else {
                        $_.ToLower()
                    }
                }

            return @('event', 'errand', 'deadline') -contains $type `
                -and $when -match '\d{4}-\d{2}-\d{2}(-\{4})?' # Uses DateTimeFormat
        }

        function Test-ActionItemIsTodayOnly {
            Param(
                [PsCustomObject]
                $ActionItem
            )

            return @('todayonly', 'today-only', 'today only') `
                -contains $ActionItem.type.ToLower()
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

            if (-not $result.Success) {
                $InputObject | Add-Member `
                    -MemberType 'NoteProperty' `
                    -Name $result.Name `
                    -Value $result.Value `
            }

            return $result.Value
        }

        function Test-DateIsInRange {
            Param(
                [DateTime]
                $Date,

                [DateTime]
                $StartDate = (Get-Date),

                [Nullable[DateTime]]
                $EndDate
            )

            $inRange = $StartDate.Year -eq $Date.Year -and
                $StartDate.Month -eq $Date.Month -and
                $StartDate.Day -eq $Date.Day

            if ($null -eq $EndDate) {
                return $inRange
            }

            return $inRange -and
                $EndDate.Year -ge $Date.Year -and
                $EndDate.Month -ge $Date.Month -and
                $EndDate.Day -ge $Date.Day
        }

        function Test-TimeFrameIncludesNow {
            Param(
                [PsCustomObject]
                $InputObject,

                [DateTime]
                $StartDate
            )

            $recurringStart = $InputObject |
                Get-NoteProperty -PropertyName 'startdate'

            if ($recurringStart.Success) {
                $startWhen = [TimeItem]::new($recurringStart.Value)

                if ($startWhen.DateTime -gt $StartDate) {
                    return $false
                }
            }

            $recurringEnd = $InputObject |
                Get-NoteProperty -PropertyName 'enddate'

            if ($recurringEnd.Success) {
                $endWhen = [TimeItem]::new($recurringEnd.Value)

                if ($endWhen.DateTime -lt $StartDate) {
                    # expired
                    return $false
                }
            }

            return $true
        }

        $setting =
            "$PsScriptRoot/../res/setting.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json

        if ($null -eq $Default) {
            $Default = ([PsCustomObject]@{
                when = (Get-Date -f HHmm)
                type = 'todayonly'
                every = 'none'
            })
        }
    }

    Process {
        $list = @()

        $discard = $null -eq $InputObject `
            -or -not (Test-TimeFrameIncludesNow `
            -InputObject $InputObject `
            -DateTime $StartDate)

        if ($discard) {
            # discard
            return $list
        }

        $getList = $InputObject `
            | Get-NoteProperty -PropertyName 'list'

        if ($getList.Success) {
            foreach ($subitem in $getList.Value.list_subitem) {
                $newItem = $InputObject `
                    | Get-NewActionItem `
                        -ExcludeProperty 'list' `
                        -AddProperty ($subitem.PsObject.Properties) `
                    | Get-Schedule_FromTable `
                        -StartDate:$StartDate `
                        -EndDate:$EndDate `
                        -Default:$Default

                $list += @($newItem)
            }

            return $list
        }

        $schedWhen = Add-NoteProperty `
            -InputObject $InputObject `
            -PropertyName 'when' `
            -Default $Default

        if ($InputObject.PsObject.Properties.Name -notcontains 'when') {
            # discard
            return $list
        }

        if ($null -eq $schedWhen) {
            $schedWhen = ""
        }

        # The sched's 'when' property is a list of date-times with other info
        # nested under each. Each one represents a separate entry in the time
        # table.
        if ($schedWhen -isnot [String]) {
            foreach ($property in (Get-NoteProperty $schedWhen)) {
                $obj = $InputObject.PsObject.Copy()
                $obj.when = "$($property.Name)"
                $whenValue = $property.Value

                if ($whenValue -is [PsCustomObject]) {
                    foreach ($subproperty in (Get-NoteProperty $whenValue)) {
                        $obj | Add-Member `
                            -MemberType 'NoteProperty' `
                            -Name $subproperty.Name `
                            -Value $subproperty.Value
                    }
                }

                $what = Get-Schedule_FromTable `
                    -InputObject $obj `
                    -StartDate:$StartDate `
                    -EndDate:$EndDate `
                    -Default:$Default

                $list += @($what)
            }

            return $list
        }

        $schedWhen = $schedWhen.ToLower()

        $schedType = (Add-NoteProperty `
            -InputObject $InputObject `
            -PropertyName 'type' `
            -Default $Default).ToLower()

        if ('todo' -eq $schedType) {
            if ($InputObject.complete) {
                # expired, discard
                return $list
            }

            $capture = [Regex]::Match( `
                $schedWhen, `
                '(?<checkbox>\s*\[ \] )?(?<datetime>.*)$' `
            )

            $schedWhen = $capture.Groups['datetime'].Value

            if ($capture.Groups['checkbox'].Success) {
                $InputObject | Add-Member `
                    -MemberType NoteProperty `
                    -Name complete `
                    -Value $false
            }
        }

        # (karlr 2024-09-22): fix issue of deadline items not showing
        # The 'every' property means something different for 'deadline' items.
        if ('deadline' -eq $schedType `
            -and $Default.PsObject.Properties.Name -contains 'every' `
        ) {
            $Default.every = 'none'
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

        $timeItem = [TimeItem]::new($schedWhen)
        $date = $StartDate

        switch -Regex ($schedEvery) {
            'none' {
                $date = $timeItem.DateTime

                if ($todayOnlyEvent) {
                    # todo: remove
                    try {
                        # expired if evaluates StartDate greater than Date
                        $isInRange = Test-DateIsInRange `
                            -Date $date `
                            -StartDate $StartDate `
                            -EndDate:$EndDate
                    }
                    catch {
                        Write-Host "[$schedWhen]"
                        throw $_
                    }

                    if ($isInRange) {
                        # Discard 'when' and 'every' and use a standard date-time
                        # as the new 'when'.
                        $what = Get-NewActionItem `
                            -ActionItem $InputObject `
                            -Date $date

                        $list += @($what)
                    }

                    return $list
                }

                if ($oneDayEvent) {
                    # todo: remove
                    try {
                        # Discard 'when' and 'every' and use a standard date-time
                        # as the new 'when'.
                        $what = Get-NewActionItem `
                            -ActionItem $InputObject `
                            -Date $date
                    }
                    catch {
                        Write-Host "[$schedWhen]"
                        throw $_
                    }

                    $list += @($what)
                    return $list
                }

                break
            }

            # every day
            'day' {
                # must have a time of day
                $invalid = -not $timeItem.TimeString

                if ($invalid) {
                    return
                }

                break
            }

            'week' {
                # must have a day code and time of day
                $invalid =
                    -not $timeItem.DayOfWeek -or
                    -not $timeItem.TimeString

                if ($invalid) {
                    return
                }

                $date = [TimeItem]::NextDate(
                    $StartDate,
                    $timeItem.DayOfWeek
                )

                break
            }

            'month' {
                # must have an identifiable date-time
                if ($null -eq $timeItem.DateTime) {
                    return
                }

                # todo: Constructing a date-time object elides the time item's intent
                $dtItem = $timeItem.TryDifferentItem(
                    $StartDate.Year,
                    $StartDate.Month,
                    $null,
                    $null,
                    $null,
                    $null
                )

                # generate a new row for each day code
                foreach ($dayItem in @($dtItem.TryAddMonths(-1), $($dtItem.TryAddMonths(1)))) {
                    # An every-day-code is shorthand for every-week-when-day-code.
                    $obj = $InputObject.PsObject.Copy()
                    $obj.every = 'none'
                    
                    # todo (karlr 2026-04-02): Using a date-time object fails
                    $obj.when = $dayItem.ToString()

                    $what = Get-Schedule_FromTable `
                        -InputObject $obj `
                        -StartDate:$StartDate `
                        -EndDate:$EndDate `
                        -Default:$Default

                    $list += @($what)
                }

                return $list
            }

            # comma-separated day codes
            '[A-Za-z]+(\s*,\s*[A-Za-z]+)*' {
                # must have a time of day
                $invalid = -not $timeItem.TimeString

                $days = $schedEvery -Split '\s*,\s*'

                # discard non-day codes and duplicates
                $days = $days | where {
                    @('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun') `
                        -contains $_
                } | select -Unique

                # generate a new row for each day code
                foreach ($day in $days) {
                    # An every-day-code is shorthand for every-week-when-day-code.
                    $obj = $InputObject.PsObject.Copy()
                    $obj.every = 'week'
                    $obj.when = "$day-$($timeItem.TimeString)"

                    $what = Get-Schedule_FromTable `
                        -InputObject $obj `
                        -StartDate:$StartDate `
                        -EndDate:$EndDate `
                        -Default:$Default

                    $list += @($what)
                }

                return $list
            }
        }

        if ($null -eq $date) {
            $date = $StartDate
        }

        if ($schedWhen -in $setting.NoteNotActive) {
            # discard
            return $list
        }

        if ($schedWhen -in $setting.NoteReschedule) {
            $InputObject.type = 'todo'
            $InputObject.what = "reappoint: $($InputObject.what)"

            $complete = Add-NoteProperty `
                -InputObject $InputObject `
                -PropertyName 'complete' `
                -Default ([PsCustomObject]@{
                    complete = $false
                })

            $date = $date.AddDays(-1)
        }

        $time = if ($timeItem.TimeString) {
            $timeItem.GetTimeFromString()
        }
        else {
            $StartDate
        }

        $dateTime = Get-Date `
            -Year $date.Year `
            -Month $date.Month `
            -Day $date.Day `
            -Hour $time.Hour `
            -Minute $time.Minute `
            -Second 0 `
            -Millisecond 0

        $isInRange = Test-DateIsInRange `
            -Date $dateTime `
            -StartDate $StartDate `
            -EndDate:$EndDate

        $addTodo =
            'todo' -eq $InputObject.type `
                -and -not $InputObject.complete `
                -and $StartDate -ge $dateTime

        $addToday =
            ($todayOnlyEvent `
                -and $isInRange) `
            -or `
            $addTodo `
            -or `
            (-not $todayOnlyEvent `
                -and 'todo' -ne $InputObject.type)

        if ($addTodo) {
            $dateTime = $StartDate
        }

        if ($addToday) {
            $what = Get-NewActionItem `
                -ActionItem $InputObject `
                -Date $dateTime

            $list += @($what)
        }
        # else: expired and isInRange evaluated StartDate greater than Date

        return $list
    }
}

