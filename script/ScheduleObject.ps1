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
        $day = $null
        $month = $null
        $year = $null
        $hostForeground =
            (Get-Host).Ui.RawUi.ForegroundColor
    }

    Process {
        $when = $ActionItem.when
        $newDay =
                 $day -ne $when.Day `
            -or $month -ne $when.Month `
            -or $year -ne $when.Year

        if ($newDay) {
            $day = $when.Day
            $month = $when.Month
            $year = $when.Year

            $heading = "$($when.DayOfWeek) ($(Get-Date $when -f yyyy_MM_dd))"

            Write-Host
            Write-Host $heading -Foreground DarkGray
            Write-Host "$("-" * $heading.Length)" -Foreground DarkGray
        }

        $icon = $null
        $foreground = $null

        switch ($ActionItem.type) {
            'deadline' {
                $icon = '[!]'
                $foreground = 'Red'
            }

            default {
                $icon = '   '
                $foreground = $hostForeground
            }
        }

        $displayItem = [PsCustomObject]@{
            When = "$(Get-Date $when -f HH:mm)"
            Type = $icon
            What = $ActionItem.what
        }

        $str = $displayItem `
            | Format-Table -HideTableHeaders `
            | Out-String

        $str = $str.Trim()

        if (-not [String]::IsNullOrWhiteSpace($str)) {
            Write-Host $str -Foreground $foreground
        }
    }

    End {
        Write-Host
    }
}

<#
.EXAMPLE
cat .\sched\*.md | Get-Schedule
#>
function Get-Schedule {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Line,

        [String]
        $StartDate = $(Get-Date -f 'yyyy_MM_dd')
    )

    Begin {
        $content = @()
    }

    Process {
        $content += @($Line)
    }

    End {
        $date = [DateTime]::ParseExact( `
            $StartDate, `
            'yyyy_MM_dd', `
            $null `
        )

        $what = $content `
            | Get-MarkdownTable

        return $what.sched `
            | Get-Schedule_FromTable `
                -StartDate $date `
            | Sort-Object `
                -Property when `
            | Where-Object {
                $date -lt $_.when
            }
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
        $capture = [Regex]::Match($Line, '^(?<indent>\s*)((?<header>#+)|(?<list_item_delim>\-)\s)\s*(?<content>.+)$')
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
            "^\s*(?<key>[^:`"]+)\s*:\s*(?<value>.*)\s*$" `
        )

        $key = $capture.Groups['key']

        if ($key.Success) {
            $content = $key.Value
            $stack[$level] = $capture.Groups['value'].Value
        } else {
            $stack[$level] = [PsCustomObject]@{}
        }

        $property = $parent.PsObject.Properties | where {
            $_.Name -eq $TableRow.Content
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
        $StartDate = $(Get-Date)
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
    }

    Process {
        $schedWhen = $InputObject.when.ToLower()

        $capture = [Regex]::Match( `
            $schedWhen, `
            "((?<day>\w{3})-)?(?<time>\d{4})?" `
        )

        $schedDay = $capture.Groups['day'].Value
        $schedTime = $capture.Groups['time'].Value
        $schedEvery = $InputObject.every.ToLower()

        $list = @()

        switch ($schedEvery) {
            'day' {
                $invalid =
                    [String]::IsNullOrWhiteSpace($schedTime)

                if ($invalid) {
                    return
                }

                $time = [DateTime]::ParseExact($schedTime, 'HHmm', $null)

                $dateTime = Get-Date `
                    -Year $StartDate.Year `
                    -Month $StartDate.Month `
                    -Day $StartDate.Day `
                    -Hour $time.Hour `
                    -Minute $time.Minute `
                    -Second 0

                $what = Get-NewActionItem `
                    -ActionItem $InputObject `
                    -Date $dateTime

                $list += @($what)
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

                $time = [DateTime]::ParseExact($schedTime, 'HHmm', $null)

                $dateTime = Get-Date `
                    -Year $date.Year `
                    -Month $date.Month `
                    -Day $date.Day `
                    -Hour $time.Hour `
                    -Minute $time.Minute `
                    -Second 0

                $what = Get-NewActionItem `
                    -ActionItem $InputObject `
                    -Date $dateTime

                $list += @($what)
            }
        }

        return $list
    }
}

