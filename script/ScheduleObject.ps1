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

            switch ($ActionItem.type) {
                'todo' {
                    $what = "todo: $what"
                    $icon = "[ ]"
                    $foreground = 'Yellow'
                }

                'deadline' {
                    $icon = '[!]'
                    $foreground = 'Red'
                }

                'event' {
                    $what = "event: $what"
                    $foreground = 'Green'
                }

                default {
                    if (($ActionItem | Get-NoteProperty -PropertyName 'complete').Success) {
                        $icon = "[$((if ($ActionItem.complete) { 'x' } else { ' ' }))]"
                        $what = "todo: $what"
                        $foreground = 'Yellow'
                    }
                    else {
                        $icon = '   '
                        $foreground = $hostForeground
                    }
                }
            }

            $displayItem = [PsCustomObject]@{
                When = "$(Get-Date $ActionItem.when -f HH:mm)"
                Type = $icon
                What = $what
            }

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
                -InputObject '[Error: action item was found to be null]'

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

        $ActionItem | Write-ActionItem

        $subtree = $ActionItem | Find-Subtree `
            -PropertyName 'complete' `
            -Parent $ActionItem.what

        if ($Verbose -and $null -ne $subtree) {
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
        $StartDate
    )

    Begin {
        $content = @()

        if (-not $StartDate) {
            $StartDate = $(Get-Date -f 'yyyy_MM_dd')
        }
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

                if (-not (Test-Path $DirectoryPath)) {
                    return $what
                }

                $mdFiles = Join-Path $DirectoryPath "*.md"

                $setting =
                    cat "$PsScriptRoot\..\res\setting.json" `
                    | ConvertFrom-Json

                $defaultsPath =
                    Join-Path `
                        $DirectoryPath `
                        $setting.ScheduleDefaultsFile

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
                        $setting.ScheduleDefaultsFile `
                            -ne $_.Name.ToLower()
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
                                $date -le $_.when
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
        $StartDate
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

        return $list `
            + @($Table | Get-Schedule_FromTable `
                -StartDate $date
            ) `
            | Sort-Object `
                -Property when `
            | Where-Object {
                $date -le $_.when
            }
    }
}

function Write-MarkdownTree {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [Int]
        $Level = 0,

        [Switch]
        $AsTree
    )

    Process {
        if ($null -eq $InputObject) {
            return
        }

        # karlr (2023_01_12):
        # I strongly believe I shouldn't have to do this.
        switch -Regex ($InputObject.GetType().Name) {
            '.*\[\]$' {
                foreach ($subitem in $InputObject) {
                    Write-MarkdownTree " " $Level
                    Write-MarkdownTree $subitem ($Level + 1)
                }
            }

            'PsCustomObject' {
                $properties = $InputObject.PsObject.Properties `
                    | where {
                        'NoteProperty' -eq $_.MemberType
                    }

                foreach ($property in $properties) {
                    if (-not $AsTree `
                        -and $property.Name -eq 'complete' `
                        -and $property.Value -is [Boolean])
                    {
                        continue
                    }

                    if ($property.Name -eq 'list_subitem') {
                        Write-MarkdownTree `
                            $property.Value `
                            $Level

                        continue
                    }

                    $list = Write-MarkdownTree `
                        $property.Value `
                        ($Level + 1)

                    $inline =
                        [String]::IsNullOrWhiteSpace($property.Name) `
                        -and @($list).Count -gt 0

                    if ($inline) {
                        Write-Output "- $($list[0].Trim())"
                        Write-Output $list[1 .. ($list.Count - 1)]
                        continue
                    }

                    $actionItemCapture = [PsCustomObject]@{
                        Success = $false
                    }

                    $token = ''

                    if (-not $AsTree) {
                        $actionItemCapture = $property.Value `
                            | Get-NoteProperty `
                                -PropertyName 'complete'

                        $token = if ($actionItemCapture.Value) { 'x' } else { ' ' }
                    }

                    $content = if ($actionItemCapture.Success) {
                        "[$token] $($property.Name)"
                    } else {
                        $property.Name
                    }

                    Write-Output "$('  ' * $Level)- $content"
                    $list
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
        $PropertyName,

        [String]
        $Parent
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
                    $subresults += @((Find-Subtree `
                        -InputObject $InputObject[$i] `
                        -PropertyName $PropertyName `
                        -Parent:$Parent))

                    $i = $i + 1
                }
            }

            'PsCustomObject' {
                $properties = $InputObject.PsObject.Properties `
                    | where {
                        'NoteProperty' -eq $_.MemberType
                    }

                if ($null -eq $properties) {
                    return $subresults
                }

                if ($PropertyName -in $properties.Name) {
                    if ($Parent) {
                        $subresults += @(
                            [PsCustomObject]@{
                                parent = $Parent
                                child = $InputObject
                            }
                        )
                    }
                    else {
                        $subresults += @($InputObject)
                    }
                }
                else {
                    if ($Parent) {
                        foreach ($property in $properties) {
                            $subresults += @((Find-Subtree `
                                -InputObject $property.Value `
                                -PropertyName $PropertyName `
                                -Parent $property.Name))
                        }
                    }
                    else {
                        foreach ($property in $properties) {
                            $subresults += @((Find-Subtree `
                                -InputObject $property.Value `
                                -PropertyName $PropertyName))
                        }
                    }
                }
            }
        }

        return $subresults
    }
}

function Get-SubtreeRotation {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [String[]]
        $RotateProperty
    )

    Begin {
        $tree = [PsCustomObject]@{}
    }

    Process {
        if ([String]::IsNullOrEmpty($RotateProperty)) {
            return $InputObject
        }

        $properties = $InputObject.PsObject.Properties
        $subtree = [PsCustomObject]@{}

        $rotate = $properties | where {
            $_.Name -in $RotateProperty
        }

        if ($null -eq $rotate) {
            return $InputObject
        }

        # For every property name submitted, make an attempt to create a
        # new object with rotated properties, but return on first successful
        # occurrence
        foreach ($attempt in $rotate) {
            # Create an object identical to the input object sans the
            # properties to be rotated
            $properties | where {
                $_.Name -notin $RotateProperty
            } | foreach {
                $subtree | Add-Member `
                    -MemberType NoteProperty `
                    -Name $_.Name `
                    -Value $_.Value
            }

            switch ($attempt.Value) {
                { $_ -is [String] } {
                    # Graft the newly created object as subtree to the new
                    # tree, with the rotated property as the parent
                    $tree | Add-Member `
                        -MemberType NoteProperty `
                        -Name $_ `
                        -Value $subtree
                }

                { $_ -is [PsCustomObject] } {
                    $subproperties = $_.PsObject.Properties | where {
                        $_.MemberType -eq 'NoteProperty'
                    }

                    foreach ($subproperty in $subproperties) {
                        $subtreeCopy = $subtree.PsObject.Copy()

                        $subtreeCopy | Add-Member `
                            -MemberType NoteProperty `
                            -Name $attempt.Name `
                            -Value $subproperty.Value

                        $tree | Add-Member `
                            -MemberType NoteProperty `
                            -Name $subproperty.Name `
                            -Value $subtreeCopy
                    }
                }
            }

            # return on first successful occurrence
            break
        }
    }

    End {
        if ([String]::IsNullOrEmpty($RotateProperty)) {
            return $InputObject
        }

        return $tree
    }
}

<#
.PARAMETER DepthLimit
Note: Inline or folded trees can escape the depth limit
#>
function Get-MarkdownTable {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $Line,

        [Int]
        $DepthLimit = -1
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

        if (-1 -ne $DepthLimit) {
            $table = $table | where {
                $_.Level -le $DepthLimit
            }
        }

        $table = $table `
            | Get-MarkdownTree_FromTable `
                -HighestLevel $what.HighestLevel `
            | where { -not (Test-EmptyObject $_) }

        return $table
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
        $capture = [Regex]::Match($Line, '^(?<indent>\s*)((?<header>#+)|(?<list_item_delim>\-|\*|\d+\.)\s)\s*(?<content>.+)?$')
        $header = $capture.Groups['header']
        $indent = $capture.Groups['indent']

        $type = if ($capture.Groups['list_item_delim'].Success) {
            if ($capture.Groups['content'].Success) {
                'ListItem'
            } else {
                'UnnamedRow'
            }
        } elseif ($header.Success) {
            'Header'
        } else {
            'None'
        }

        if ('None' -eq $type) {
            return
        }

        if ('Header' -eq $type) {
            $level = $header.Length
        }
        elseif ('Header' -eq $prevType) {
            $level = $level + 1
        }
        elseif ($indent.Length -ne $indentLength) {
            $level += ($indent.Length - $indentLength) / 2
        }

        $indentLength = $indent.Length
        $prevType = $type

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

function Test-EmptyObject {
    Param(
        [PsCustomObject]
        $InputObject
    )

    return 0 -eq @($InputObject.PsObject.Properties).Count
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
        function Add-Property {
            Param(
                $InputObject,

                [String]
                $Name,

                $Value
            )

            $property = $InputObject.PsObject.Properties | where {
                $_.Name -eq $Name
            }

            if ($null -eq $property) {
                $InputObject | Add-Member `
                    -MemberType NoteProperty `
                    -Name $Name `
                    -Value $Value

                return
            }

            if (1 -eq @($property.Value).Count) {
                $property.Value = @($property.Value)
            }

            if ((Test-EmptyObject $property.Value[-1])) {
                $property.Value[-1] = @($Value)
            }
            else {
                $property.Value += @($Value)
            }
        }

        $stack = @($null) * ($HighestLevel + 1)
        # $keys = @($null) * ($HighestLevel + 1)
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

        $keyCapture = $capture.Groups['key']

        if ($keyCapture.Success) {
            $key = $keyCapture.Value
            $value = $capture.Groups['value'].Value
            $stack[$level] = $value
            $content = $key

        # # DRAWINGBOARD
        # # ------------
        # } elseif (2 -eq $level -and (Test-EmptyObject $parent)) {
        #     $stack[$level] = [PsCustomObject]@{ what = $key }
        #
        #     Add-Property `
        #         -InputObject $stack[0] `
        #         -Name $keys[1] `
        #         -Value $stack[$level]
        #
        #     return

        } else {
            $stack[$level] = [PsCustomObject]@{}
        }

        $checkBoxCapture = [Regex]::Match( `
            $content, `
            "\[(?<check>x| )\]\s*(?<content>.*)" `
        )

        if ($checkBoxCapture.Success) {
            $content = $checkBoxCapture.Groups['content'].Value

            Add-Property `
                -InputObject $stack[$level] `
                -Name 'complete' `
                -Value ($checkBoxCapture.Groups['check'].Value -eq 'x')
        }

        if ([String]::IsNullOrWhiteSpace($content)) {
            $content = "list_subitem"

            # DRAWINGBOARD
            # ------------
            # Add-Property `
            #     -InputObject $stack[$level - 2] `
            #     -Name 'list' `
            #     -Value $stack[$level]
            # 
            # return
        }

        Add-Property `
            -InputObject $parent `
            -Name $content `
            -Value $stack[$level]

        # $keys[$level] = $content
    }

    End {
        return $stack[0]
    }
}

function Get-NoteProperty {
    Param(
        [Parameter(ValueFromPipeline = $true)]
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

    $result = if ($null -eq $properties -or @($properties).Count -eq 0) {
        [PsCustomObject]@{
            Success = $false
            Name = $PropertyName
            Value = $null
        }
    } elseif ($PropertyName -in $properties.Name) {
        [PsCustomObject]@{
            Success = $true
            Name = $PropertyName
            Value = $InputObject.$PropertyName
        }
    } elseif ($null -ne $Default) {
        [PsCustomObject]@{
            Success = $false
            Name = $PropertyName
            Value = $Default.$PropertyName
        }
    } else {
        [PsCustomObject]@{
            Success = $false
            Name = $PropertyName
            Value = $null
        }
    }

    return $result
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
                $Date,

                [DateTime]
                $Today = (Get-Date)
            )

            return $Today.Year -eq $Date.Year `
                -and $Today.Month -eq $Date.Month `
                -and $Today.Day -eq $Date.Day
        }
    }

    Process {
        $list = @()

        if ($null -eq $InputObject) {
            return $list
        }

        $getList = $InputObject | Get-NoteProperty -PropertyName 'list'

        if ($getList.Success) {
            foreach ($subitem in $getList.Value.list_subitem) {
                $newItem = $InputObject | Get-NewActionItem `
                    -ExcludeProperty 'list' `
                    -AddProperty ($subitem.PsObject.Properties)

                $newItem = $newItem | Get-Schedule_FromTable `
                    -StartDate:$StartDate `
                    -Default:$Default

                $list += @($newItem)
            }

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
        $date = $StartDate

        switch -Regex ($schedEvery) {
            'none' {
                $date = $dateTimeResult.DateTime

                if ($todayOnlyEvent) {
                    $isToday = Test-DateIsToday `
                        -Date $date `
                        -Today $StartDate

                    if ($isToday) {
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

        if ($null -eq $date) {
            $date = $StartDate
        }

        $time = $StartDate

        if ([String]::IsNullOrWhiteSpace($schedWhen)) {
            $InputObject.type = 'todo'
            $InputObject.what = "reappoint: $($InputObject.what)"

            $complete = Add-NoteProperty `
                -InputObject $InputObject `
                -PropertyName 'complete' `
                -Default $false

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

        $isToday =
            Test-DateIsToday `
                -Date $dateTime `
                -Today $StartDate

        $addTodo =
            'todo' -eq $InputObject.type `
                -and -not $InputObject.complete `
                -and $StartDate -ge $dateTime

        $addToday =
            ($todayOnlyEvent `
                -and $isToday) `
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

