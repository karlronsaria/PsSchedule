<#
.SYNOPSIS
f: tree -> markdown
#>
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
                    Write-Output $list
                }
            }

            default {
                Write-Output "$('  ' * $Level)- $InputObject"
            }
        }
    }
}

<#
.SYNOPSIS
f: tree -> str -> tree
f: tree -> str -> str -> tree
#>
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

                $subresults = @(while ($i -lt $InputObject.Count) {
                    Find-Subtree `
                        -InputObject $InputObject[$i] `
                        -PropertyName $PropertyName `
                        -Parent:$Parent

                    $i = $i + 1
                })
            }

            'PsCustomObject' {
                $properties = $InputObject.PsObject.Properties `
                    | where {
                        'NoteProperty' -eq $_.MemberType
                    }

                if ($null -eq $properties) {
                    return $subresults
                }

                $subresults += @( `
                    if ($PropertyName -in $properties.Name) {
                        if ($Parent) {
                            [PsCustomObject]@{
                                parent = $Parent
                                child = $InputObject
                            }
                        }
                        else {
                            $InputObject
                        }
                    }
                    else {
                        foreach ($property in $properties) {
                            $params = @{
                                InputObject = $property.Value
                                PropertyName = $PropertyName
                            }

                            if ($Parent) {
                                $params | Add-Member `
                                    -MemberType NoteProperty `
                                    -Name Parent `
                                    -Value $property.Name
                            }

                            Find-Subtree @params
                        }
                    } `
                )
            }
        }

        return $subresults
    }
}

<#
.SYNOPSIS
f: tree -> tree
#>
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
.SYNOPSIS
f: str -> tree
f: str -> int -> tree
.PARAMETER DepthLimit
Note: Inline or folded trees can escape the depth limit
#>
function Get-MarkdownTree {
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
        function Add-Property {
            Param(
                $InputObject,

                [String]
                $Name,

                $Value,

                [Switch]
                $Overwrite,

                [Switch]
                $Table
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

            if (@($property.Value).Count -eq 1) {
                $property.Value = @($property.Value)
            }

            if ((Test-EmptyObject $property.Value[-1])) {
                $property.Value[-1] = @($Value)
            }
            else {
                $property.Value += @($Value)
            }
        }

        <#
        .SYNOPSIS
        f: str -> (int, enum, str)
        #>
        function Get-LexInfo {
            Param(
                [Parameter(ValueFromPipeline = $true)]
                [String]
                $Line
            )

            Begin {
                $prevType = 'None'
                $level = 0
                $indentLength = 0
                $pattern =
                    '^(?<indent>\s*)((?<header>#+)|(?<branch_start>\-|\*|\d+\.)\s)?\s*(?<content>.+)?$'
            }

            Process {
                $capture = [Regex]::Match($Line, $pattern)
                $header = $capture.Groups['header']
                $indent = $capture.Groups['indent']
                $content = $capture.Groups['content']
                $type = @()

                $type += if ($capture.Groups['branch_start'].Success) {
                    if ($content.Success) {
                        @('ListItem')
                    }
                    else {
                        @('UngraftedRow')
                    }
                }
                elseif ($header.Success) {
                    @('Header')
                }
                else {
                    @()
                }

                if ('Header' -notin $type `
                    -and $content.Success `
                    -and ($content.Value | Test-MdTable) `
                ) {
                    $type += @('TableRow')
                }

                if ($type.Count -eq 0) {
                    return
                }

                $level = if ('Header' -in $type) {
                    $header.Length
                }
                elseif ('Header' -in $prevType) {
                    $level + 1
                }
                elseif ($indent.Length -ne $indentLength) {
                    $level + ($indent.Length - $indentLength) / 2
                }
                else {
                    $level
                }

                $indentLength = $indent.Length
                $prevType = $type

                return [PsCustomObject]@{
                    Level = $level
                    Type = $type
                    Content = $capture.Groups['content'].Value
                }
            }
        }

        <#
        .SYNOPSIS
        f: (int, str) -> tree
        #>
        function Get-Parse {
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
                $stack = @($null) * ($HighestLevel + 1)
                # $keys = @($null) * ($HighestLevel + 1)
                $stack[0] = [PsCustomObject]@{}
                $table = $null
                $prevLevel = 0
                $prevName = ""
                $level = 0
                $tableStart = $null
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

                $stack[$level] = [PsCustomObject]@{}

                if ('TableRow' -in $TableRow.Type) {
                    if ($null -eq $table) {
                        $table = New-MdTableBuild
                        $tableStart = $TableRow
                    }

                    $table | Add-MdTableRow `
                        -RowList $content `
                        -RemoveStyling

                    return
                }
                else {
                    if ($null -ne $table) {
                        $table = ConvertTo-MdTable `
                            -TableBuild $table

                        $tempLevel = if ('ListItem' -in $tableStart.Type) {
                            $tableStart.Level - 2
                        }
                        else {
                            $prevLevel - 1
                        }

                        Add-Property `
                            -InputObject $stack[$tempLevel] `
                            -Name $prevName `
                            -Value $table

                        $table = $null
                    }

                    $prevLevel = $level
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

                    }

                    $checkBoxCapture = [Regex]::Match( `
                        $content, `
                        "\[(?<check>x| )\]\s*(?<content>.*)" `
                    )

                    if ($checkBoxCapture.Success) {
                        $content = $checkBoxCapture.Groups['content'].Value
                        $token = $checkBoxCapture.Groups['check'].Value

                        Add-Property `
                            -InputObject $stack[$level] `
                            -Name 'complete' `
                            -Value ($token -eq 'x')
                    }
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
                    $name = $content

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

        $content = @()
        $startLevel = $null
        $highestLevel = $null
    }

    Process {
        $content += @($Line)
    }

    End {
        $content = $content `
            | Get-LexInfo `
            | foreach {
                if ($null -eq $startLevel) {
                    $highestLevel = $startLevel = $_.Level
                }

                if ($_.Level -gt $highestLevel) {
                    $highestLevel = $_.Level
                }

                Write-Output $_
            }

# todo
<#
            } | foreach {
                [PsCustomObject]@{
                    Level = $_.Level - $startLevel + 1
                    Content = $_.Content
                }
#>
        return $content `
            | where {
                $_.Type.Count -gt 0
            } `
            | where {
                $DepthLimit -eq -1 -or $_.Level -le $DepthLimit
            } `
            | Get-Parse `
                -HighestLevel $highestLevel `
                -MuteProperty:$MuteProperty `
            | where {
                -not (Test-EmptyObject $_)
            }
    }
}

<#
.SYNOPSIS
f: P(key, value) -> bool
#>
function Test-EmptyObject {
    Param(
        [PsCustomObject]
        $InputObject
    )

    return 0 -eq @($InputObject.PsObject.Properties).Count
}

<#
.SYNOPSIS
f: P(key, value) -> key -> value
#>
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
        return $(if ($null -eq $properties -or @($properties).Count -eq 0) {
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
        })
    }
    catch {
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

