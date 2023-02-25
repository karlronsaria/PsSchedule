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
        $ITEM_CONTINUATION_SYMBOL = '---'

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

            $displayItems = @($displayItem)

            if ($ActionItem.PsObject.Properties.Name -contains 'to') {
                $to = $ActionItem.to
                $hour = $to.Substring(0, 2)
                $minute = $to.Substring(2)

                $displayItems +=
                    @([PsCustomObject]@{
                        When = "$(Get-Date -Hour $hour -Minute $minute -f HH:mm)"
                        Type = $icon
                        What = $ITEM_CONTINUATION_SYMBOL
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

                $endDate = if ($Week) {
                    $date.AddDays(7)
                } else {
                    $null
                }

                $what = $content `
                    | Get-MarkdownTable `
                        -MuteProperty:$setting.MuteProperties

                return $what | foreach {
                    switch ($_) {
                        'Error' { $null }
                        default {
                            $temp =
                                $_.sched `
                                | Get-Schedule_FromTable `
                                    -StartDate $date `
                                    -EndDate:$endDate `
                                    -Default:$Default

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

                        $token =
                            if ($actionItemCapture.Value) { 'x' } else { ' ' }
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
            return
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
        $DepthLimit = -1,

        [String[]]
        $MuteProperty
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
                -MuteProperty:$MuteProperty `
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
        $HighestLevel,

        [String[]]
        $MuteProperty
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
            $content = 'list_subitem'

            # DRAWINGBOARD
            # ------------
            # Add-Property `
            #     -InputObject $stack[$level - 2] `
            #     -Name 'list' `
            #     -Value $stack[$level]
            # 
            # return
        }

        if ($content -notin $MuteProperty) {
            Add-Property `
                -InputObject $parent `
                -Name $content `
                -Value $stack[$level]
        }

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

    try {
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
    catch
    {
        return [PsCustomObject]@{
            Success = $false
            Name = $PropertyName
            Value = $null
        }
    }

    return [PsCustomObject]@{
        Success = $false
        Name = $PropertyName
        Value = $null
    }
}

