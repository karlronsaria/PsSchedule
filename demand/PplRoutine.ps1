<#
Tags: kines, kinesiology, ppl, routine, fitness, workout
#>

. "$PsScriptRoot/MySchedule.ps1"
. "$PsScriptRoot/ScheduleFromTable.ps1"
. "$PsScriptRoot/ScheduleObject.ps1"

function Get-PplRoutineSequence {
    Param(
        [Int]
        $Terms,

        [PsCustomObject[]]
        $Routines,

        [PsCustomObject]
        $Rest,

        [Int[]]
        $RestDays
    )

    $index = 0
    $routineIndex = 0

    while ($index -lt $Terms) {
        if ($index % 7 -in $RestDays) {
            $Rest
        }
        else {
            $Routines[$routineIndex % $Routines.Count]
            $routineIndex++
        }

        $index++
    }
}

function Get-PplRoutineSchedule {
    [CmdletBinding(DefaultParameterSetName = 'JustGetTheSchedule')]
    Param(
        [Parameter(ParameterSetName = 'JustGetTheSchedule')]
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
                Get-Date ($date.AddDays($_)) -Format 'yyyy-MM-dd' # Uses DateTimeFormat
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
        [String]
        $StartDate,

        [Parameter(ParameterSetName = 'JustGetTheSchedule')]
        [Nullable[Int]]
        $Forecast = $null,

        [Parameter(ParameterSetName = 'AskTheScheduleAQuestion')]
        [Switch]
        $GetInceptionItem
    )

    $setting = dir "$PsScriptRoot/../res/pplroutine.setting.json" |
        Get-Content |
        ConvertFrom-Json

    if ($GetInceptionItem) {
        return $setting.StartSchedule
    }

    $modulus = 42

    if ($null -eq $Forecast) {
        $Forecast = $setting.DefaultForecast
    }

    $startSched = $setting.StartSchedule

    $startWhen = Get-DateParseVaryingLength `
        -DateString $startSched.when |
        foreach { $_.DateTime }

    $today = if ($StartDate) {
        Get-DateParseVaryingLength `
            -DateString $StartDate |
            foreach { $_.DateTime }
    }
    else {
        [DateTime]::Now
    }

    $difference = $today - $startWhen.Date

    if ($difference.Days -lt 0) {
        return @()
    }

    $sequence = Get-PplRoutineSequence `
        -Terms $modulus `
        -Routines $setting.Routines `
        -Rest $([PsCustomObject]@{
            Name = "Rest"
            Groups = @()
        }) `
        -RestDays @(3, 6)

    $terms = $difference.Days + $forecast
    $sequence = $sequence * ($terms / $modulus + $($terms % $modulus -gt 0))

    $sequence[$difference.Days .. ($difference.Days + $forecast)] |
    foreach -Begin {
        $day = [DateTime]::new(
            $today.Year,
            $today.Month,
            $today.Day,
            $startWhen.Hour,
            $startWhen.Minute,
            $startWhen.Second
        )
    } -Process {
        [PsCustomObject]@{
            what = "$($_.Name)$(if ($_.Groups.Count -gt 0) {
                ": $($_.Groups -join ', ')"
            })"
            when = $day
            every = "none"
            type = "routine"
        }

        $day = $day.AddDays(1)
    }
}

