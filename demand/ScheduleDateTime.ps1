function Get-NextDay {
    Param(
        [ValidateSet('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun')]
        [string]
        $DayOfWeek,

        [ArgumentCompleter({
            # Uses DateTimeFormat
            return 'yyyy-MM-dd', 'yyyy-MM-dd-HHmmss', '"ddd yyyy-MM-dd"', '"ddd yyyy-MM-dd-HHmmss"'
        })]
        [string]
        $Format,

        [int]
        $Week = 0,

        [datetime]
        $StartDate = $(Get-Date)
    )

    $date = switch ($Week) {
        0 { $StartDate.AddDays(1) }
        -1 { $StartDate.AddDays(-1) }
        default { $StartDate.AddDays($Week * 7) }
    }

    if ($DayOfWeek) {
        $code = $DayOfWeek.ToLower()

        # advance to the upcoming given day of the week
        while ($code -ne ($date.DayOfWeek.ToString().Substring(0, 3).ToLower())) {
            $date = $date.AddDays(1)
        }
    }

    if ($Format) {
        return Get-Date -Date $date -Format $Format
    }

    return $date
}

enum TimeItemType {
    Error
    RecurByWeekdayAndTime
    ExactDateTimeKnown
}

<#
.DESCRIPTION
Formats
- recurring: ddd-HHmm
- date-time: yyyy-MM-dd-HHmm
- week-date-time: ddd yyyy-MM-dd-HHmm
#>
class TimeItem : System.ICloneable {
    [string] $DayOfWeek = ''
    [string] $TimeString = ''
    [datetime] $DateTime
    [TimeItemType] $Type
    
    hidden [string[]] $Parts_
    hidden [string] $Pattern_

    hidden TimeItem() {}

    # # todo: remove
    # TimeItem([datetime] $DateTime) {
    #     $this.Type = [TimeItemType]::ExactDateTimeKnown
    #     $this.DateTime = $DateTime
    # }

    TimeItem([string] $DateString) {
        $capture = [regex]::Match(
            $DateString,
            "^((?<day>[A-Za-z]{3})-)?(?<time>\d{4})$"
        )

        if ($capture.Success) {
            $this.Type = [TimeItemType]::RecurByWeekdayAndTime
            $this.DayOfWeek = $capture.Groups['day'].Value.ToLower()
            $this.TimeString = $capture.Groups['time'].Value
            return
        }

        # Discard day-of-week code
        $DateString = $DateString.Trim() -replace "^[A-Za-z]{3}(-| )", ""
        $this.Type = [TimeItemType]::ExactDateTimeKnown

        $this.Pattern_, $this.Parts_ = switch -Regex ($DateString) {
            # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}-\d{6}$" {
                'yyyy-MM-dd-HHmmss'
                'Year', 'Month', 'Day', 'Hour', 'Minute', 'Second'
                break
            }

            # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}-\d{4}$" {
                'yyyy-MM-dd-HHmm'
                'Year', 'Month', 'Day', 'Hour', 'Minute'
                break
            }

            # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}-\d{2}$" {
                'yyyy-MM-dd-HH'
                'Year', 'Month', 'Day', 'Hour'
                break
            }

            # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}$" {
                'yyyy-MM-dd'
                'Year', 'Month', 'Day'
                break
            }

            default {
                ''
                break
            }
        }

        if (-not $this.Pattern_) {
            $this.Type = [TimeItemType]::Error
            return
        }

        $this.DateTime = [DateTime]::ParseExact( `
            $DateString, `
            $this.Pattern_, `
            $null `
        )
    }

    # (karlr 2026-04-02): This cannot be made into a get-property for some reason.
    [datetime] GetTimeFromString() {
        if ($this.Type -ne [TimeItemType]::RecurByWeekdayAndTime) {
            return $null
        }

        # Uses DateTimeFormat
        return [DateTime]::ParseExact($this.TimeString, 'HHmm', $null)
    }

    [object] TryGet([string] $PropertyName) {
        if ($this.Type -ne [TimeItemType]::ExactDateTimeKnown) {
            return $null
        }

        return $this.DateTime.$PropertyName
    }
    
    [TimeItem] TryDifferentItem(
        [nullable[int]] $Year,
        [nullable[int]] $Month,
        [nullable[int]] $Day,
        [nullable[int]] $Hour,
        [nullable[int]] $Minute,
        [nullable[int]] $Second
    ) {
        $temp = [TimeItem] $this.Clone()

        if ($this.Type -ne [TimeItemType]::ExactDateTimeKnown) {
            return $temp
        }
        
        $temp.DateTime = Get-Date `
            -Year $(
                if ($null -eq $Year) {
                    $this.DateTime.Year
                } else {
                    $Year
                }
            ) `
            -Month $(
                if ($null -eq $Month) {
                    $this.DateTime.Month
                } else {
                    $Month
                }
            ) `
            -Day $(
                if ($null -eq $Day) {
                    $this.DateTime.Day
                } else {
                    $Day
                }
            ) `
            -Hour $(
                if ($null -eq $Hour) {
                    $this.DateTime.Hour
                } else {
                    $Hour
                }
            ) `
            -Minute $(
                if ($null -eq $Minute) {
                    $this.DateTime.Minute
                } else {
                    $Minute
                }
            ) `
            -Second $(
                if ($null -eq $Second) {
                    $this.DateTime.Second
                } else {
                    $Second
                }
            )

        return $temp
    }
    
    [object] Clone() {
        $temp = [TimeItem]::new()
        $temp.Type = $this.Type
        $temp.DayOfWeek = $this.DayOfWeek
        $temp.TimeString = $this.TimeString
        $temp.DateTime = $this.DateTime
        $temp.Parts_ = $this.Parts_
        $temp.Pattern_ = $this.Pattern_
        return $temp
    }

    [string] ToString() {
        return $(if ($this.DateTime) {
            # Uses DateTimeFormat
            Get-Date $this.DateTime -Format $this.Pattern_
        }
        else {
            # Uses DateTimeFormat
            "$($this.DayOfWeek)-$($this.TimeString)"
        })
    }
    
    [int[]] Parts() {
        return $(if ($this.Type -eq [TimeItemType]::ExactDateTimeKnown) {
            $this.Parts | ForEach-Object {
                $this.DateTime.$_
            }
        }
        else {
            @()
        })
    }

    # # todo: remove
    # static [TimeItem] Now() {
    #     return [TimeItem]::new((Get-Date))
    # }

    [TimeItem] TryAddDays([int] $Days) {
        if ($this.Type -ne [TimeItemType]::ExactDateTimeKnown) {
            return $null
        }
        
        $temp = $this.Clone()
        $temp.DateTime = $temp.DateTime.AddDays($Days)
        return $temp
    }

    [TimeItem] TryAddMonths([int] $Months) {
        if ($this.Type -ne [TimeItemType]::ExactDateTimeKnown) {
            return $null
        }

        $temp = $this.Clone()
        $temp.DateTime = $temp.DateTime.AddMonths($Months)
        return $temp
    }

    static [string]
    GetWeekDayCode([datetime] $DateTime) {
        return $DateTime.DayOfWeek.ToString().Substring(0, 3).ToLower()
    }

    [TimeItem]
    NextDate([string] $DayCode) {
        # fail-fast

        if ($this.Type -ne [TimeItemType]::ExactDateTimeKnown) {
            return $null
        }

        $temp = $this.Clone()

        # advance to the upcoming given day of the week
        while ($DayCode -ne $temp.DayOfWeek) {
            $temp = $temp.AddDays(1)
        }

        return $temp
    }

    static [datetime]
    NextDate([datetime] $DateTime, [string] $DayCode) {
        # fail-fast

        $temp = $DateTime

        while ($DayCode -ne [TimeItem]::GetWeekDayCode($temp)) {
            $temp = $temp.AddDays(1)
        }

        return $temp
    }
}



