. "$PsScriptRoot\ScheduleObject.ps1"

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

        $EndDate,

        [PsCustomObject]
        $Default
    )

    Begin {
        $setting = dir "$PsScriptRoot/../res/setting.json" |
            cat |
            ConvertFrom-Json

        if ($null -eq $Default) {
            $Default = ([PsCustomObject]@{
                when = (Get-Date -f HHmm)
                type = 'todayonly'
                every = 'none'
            })
        }

        function Get-WeekDayCode {
            Param(
                [DateTime]
                $Date
            )

            return $Date.DayOfWeek.ToString().Substring(0, 3).ToLower()
        }

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

            $list = foreach ($item in @('when', 'type')) {
                $temp = $ActionItem.$item

                if ($null -eq $temp) {
                    $null
                } else {
                    $temp.ToLower()
                }
            }

            $when = $list[0]
            $type = $list[1]

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
                "^((?<day>\w{3})-)?(?<time>\d{4})?$" `
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

            $DateString = $DateString.Trim()

            $pattern = switch -Regex ($DateString) {
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

                $EndDate
            )

            if ($null -eq $EndDate) {
                return $StartDate.Year -eq $Date.Year `
                    -and $StartDate.Month -eq $Date.Month `
                    -and $StartDate.Day -eq $Date.Day
            }

            return $StartDate.Year -le $Date.Year
                -and $StartDate.Month -le $Date.Month `
                -and $StartDate.Day -le $Date.Day `
                -and $EndDate.Year -ge $Date.Year `
                -and $EndDate.Month -ge $Date.Month `
                -and $EndDate.Day -ge $Date.Day
        }

        function Test-TimeFrameIncludesNow {
            Param(
                [PsCustomObject]
                $InputObject,

                [DateTime]
                $StartDate
            )

            $recurringStart = $InputObject `
                | Get-NoteProperty -PropertyName 'startdate'

            if ($recurringStart.Success) {
                $startWhen = Get-DateParseVaryingLength `
                    -DateString $recurringStart.Value

                if ($startWhen.DateTime -gt $StartDate) {
                    return $false
                }
            }

            $recurringEnd = $InputObject `
                | Get-NoteProperty -PropertyName 'enddate'

            if ($recurringEnd.Success) {
                $endWhen = Get-DateParseVaryingLength `
                    -DateString $recurringEnd.Value

                if ($endWhen.DateTime -lt $StartDate) {
                    return $false
                }
            }

            return $true
        }
    }

    Process {
        $list = @()

        $exclude = $null -eq $InputObject `
            -or -not (Test-TimeFrameIncludesNow `
            -InputObject $InputObject `
            -DateTime $StartDate)

        if ($exclude) {
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
            return $list
        }

        if ($null -eq $schedWhen) {
            $schedWhen = ""
        }

        if (-not ($schedWhen -is [String])) {
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

        # (karlr 2024_09_22): fix issue of deadline items not showing
        if ('deadline' -eq $schedType) {
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

        $dateTimeResult = Get-DateParseVaryingLength `
            -DateString $schedWhen

        $schedDay = $dateTimeResult.Day
        $schedTime = $dateTimeResult.Time
        $date = $StartDate

        switch -Regex ($schedEvery) {
            'none' {
                $date = $dateTimeResult.DateTime

                if ($todayOnlyEvent) {
                    $isInRange = Test-DateIsInRange `
                        -Date $date `
                        -StartDate $StartDate `
                        -EndDate:$EndDate

                    if ($isInRange) {
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

                while ( `
                    $schedDay.ToLower() -ne (Get-WeekDayCode -Date $date) `
                ) {
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
                        -EndDate:$EndDate `
                        -Default:$Default

                    $list += @($what)
                }

                return $list
            }
        }

        $time = $StartDate

        if ($null -eq $date) {
            $date = $StartDate
        }

        if ($schedWhen.ToLower() -in $setting.NoteNotActive) {
            return $list
        }

        if ($schedWhen.ToLower() -in $setting.NoteReschedule) {
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

        if (-not [String]::IsNullOrWhiteSpace($schedTime)) {
            $time = [DateTime]::ParseExact($schedTime, 'HHmm', $null)
        }

        $dateTime = Get-Date `
            -Year $date.Year `
            -Month $date.Month `
            -Day $date.Day `
            -Hour $time.Hour `
            -Minute $time.Minute `
            -Second 0 `
            -Millisecond 0

        $isInRange =
            Test-DateIsInRange `
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

        return $list
    }
}

