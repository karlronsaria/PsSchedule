function Get-NextDay {
    Param(
        [ValidateSet('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun')]
        [string]
        $Day,

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

    if ($Day) {
        $code = $Day.ToLower()

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

<#
.DESCRIPTION
Formats
- recurring: ddd-HHmm
- date-time: yyyy-MM-dd-HHmm
- week-date-time: ddd yyyy-MM-dd-HHmm
#>
class ScheduleWhen : System.ICloneable {
    [string] $Day = ''
    [string] $Time = ''
    [nullable[datetime]] $DateTime = $null

    hidden ScheduleWhen() {}

    ScheduleWhen([string] $DateString) {
        $capture = [regex]::Match( `
            $DateString, `
            "^((?<day>[A-Za-z]{3})-)?(?<time>\d{4})?$" `
        )

        if ($capture.Success) {
            $this.Day = $capture.Groups['day'].Value.ToLower()
            $this.Time = $capture.Groups['time'].Value
            $this.DateTime = $null
        }

        $DateString = $DateString.Trim()
        $DateString = $DateString -replace "^[A-Za-z]{3}(-| )", ""

        $pattern = switch -Regex ($DateString) {
            "^\d{4}-\d{2}-\d{2}-\d{6}$" { 'yyyy-MM-dd-HHmmss'; break } # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}-\d{4}$" { 'yyyy-MM-dd-HHmm'; break } # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}-\d{2}$" { 'yyyy-MM-dd-HH'; break } # Uses DateTimeFormat
            "^\d{4}-\d{2}-\d{2}$" { 'yyyy-MM-dd'; break } # Uses DateTimeFormat
            "^\d{4}$" { 'HHmm'; break }
            default { ''; break }
        }

        if ([String]::IsNullOrEmpty($pattern)) {
            return
        }

        $this.DateTime = [DateTime]::ParseExact( `
            $DateString, `
            $pattern, `
            $null `
        )
    }

    [object] Clone() {
        $temp = [ScheduleWhen]::new()
        $temp.Day = $this.Day
        $temp.Time = $this.Time
        $temp.DateTime = $this.DateTime
        return $temp
    }
}

