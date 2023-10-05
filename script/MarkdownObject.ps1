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
        $AsTree,

        [Switch]
        $BranchTables,

        [Switch]
        $NoTables
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
                    if ($NoTables) {
                        Write-MarkdownTree " " $Level -AsTree:$AsTree
                        Write-MarkdownTree $subitem ($Level + 1) -AsTree:$AsTree
                    }
                    else {
                        $table = $subitem | Write-MdTable

                        if ($BranchTables) {
                            $lead = '- '

                            foreach ($row in $table) {
                                Write-Output "$('  ' * $Level)$lead$row"
                                $lead = '  '
                            }
                        }
                        else {
                            $table
                        }
                    }
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
                            -InputObject $property.Value `
                            -Level $Level `
                            -AsTree:$AsTree

                        continue
                    }

                    $list = Write-MarkdownTree `
                        -InputObject $property.Value `
                        -Level ($Level + 1) `
                        -AsTree:$AsTree

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

        function Add-Table {
            Param(
                [PsCustomObject[]]
                $Stack,

                [PsCustomObject[]]
                $Table,

                [PsCustomObject]
                $TableStart,

                [Int]
                $PrevLevel,

                [String]
                $PrevName
            )

            $Table = ConvertTo-MdTable `
                -TableBuild $Table

            $tempLevel = if ('ListItem' -in $TableStart.Type) {
                $TableStart.Level - 2
            }
            else {
                $PrevLevel - 1
            }

            Add-Property `
                -InputObject $Stack[$tempLevel] `
                -Name $PrevName `
                -Value $Table
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
                $level = 0
                $tableBuild = $null
                $prevLevel = 0
                $prevName = ""
                $tableStart = $null

                function Convert-StackLeafToFoldedBranch {
                    Param(
                        [Object[]]
                        $Stack,

                        [Int]
                        $Level,

                        [String]
                        $PrevPropertyName
                    )

                    if (-not $Stack[$Level] -is [String]) {
                        return $Stack
                    }

                    $props = $Stack[$Level - 1].PsObject.Properties `
                        | where {
                            $_.Name -eq $PrevPropertyName
                        }

                    foreach ($prop in $props) {
                        $Stack[$Level - 1] | Add-Member `
                            -MemberType NoteProperty `
                            -Name "$($prop.Name): $($prop.Value)" `
                            -Value $Stack[$Level]

                        $Stack[$Level - 1].PsObject.Properties.Remove($prop.Name)
                    }

                    $Stack[$Level] = [PsCustomObject]@{}
                    return $Stack
                }
            }

            Process {
                $level = $TableRow.Level
                $content = $TableRow.Content

                if ($null -eq $stack[$level - 1]) {
                    return 'Error'
                }

# - [ ] est: uan
#   - sin
# 
# - est
#   - uan
#     - sin
#   - complete
#     - false

# $m = [Regex]::Match("[ ] est: uan", "^\s*(\[(?<check>x| )\] )?((?<key>[^:`"]+)\s*:\s+)?(?<value>.*)?\s*$"); $m.Groups['check']; $m.Groups['key']; $m.Groups['value']

                $capture = [Regex]::Match( `
                    $content, `
                    "^\s*(\[(?<check>x| )\] )?((?<key>[^:`"]+)\s*:\s+)?(?<value>.*)?\s*$" `
                )

                $stack[$level] = [PsCustomObject]@{}

                if ('TableRow' -in $TableRow.Type) {
                    if ($null -eq $tableBuild) {
                        $tableBuild = New-MdTableBuild
                        $tableStart = $TableRow
                    }

                    $tableBuild | Add-MdTableRow `
                        -RowList $content `
                        -RemoveStyling

                    return
                }
                else {
                    if ($null -ne $tableBuild) {
                        Add-Table `
                            -Stack $stack `
                            -Table $tableBuild `
                            -TableStart $tableStart `
                            -PrevLevel $prevLevel `
                            -PrevName $prevName

                        $tableBuild = $null
                    }

                    $checkGroup = $capture.Groups['check']

                    if ($checkGroup.Success) {
                        # $stack = Convert-StackLeafToFoldedBranch `
                        #     -Stack $stack `
                        #     -Level $level `
                        #     -PrevPropertyName $prevName

                        Add-Property `
                            -InputObject $stack[$level] `
                            -Name 'complete' `
                            -Value ($checkGroup.Value -eq 'x')
                    }

                    $prevLevel = $level
                    $keyCapture = $capture.Groups['key']

                    if ($keyCapture.Success) {
                        $key = $keyCapture.Value
                        $value = $capture.Groups['value'].Value

                        if ([String]::IsNullOrWhiteSpace($key)) {
                            $key = 'list_subitem'
                        }

                        if ($key -notin $MuteProperty) {
                            Add-Property `
                                -InputObject $stack[$level - 1] `
                                -Name $key `
                                -Value ([PsCustomObject]@{
                                    $value = $stack[$level]
                                })

                            $stack[$level - 1] = $stack[$level]
                            $prevName = $key
                        }

                        continue
                        # $stack[$level] = $value
                        # $content = $key

                    # # DRAWINGBOARD
                    # # ------------
                    # } elseif (2 -eq $level -and (Test-EmptyObject $stack[$level - 1])) {
                    #     $stack[$level] = [PsCustomObject]@{ what = $key }
                    #
                    #     Add-Property `
                    #         -InputObject $stack[0] `
                    #         -Name $keys[1] `
                    #         -Value $stack[$level]
                    #
                    #     return

                    }
                }

                $content = $capture.Groups['value']

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

                # # Reprocess key-value expression as a single property name.
                # # This only happens when a string is left behind on the stack.
                # $stack = Convert-StackLeafToFoldedBranch `
                #     -Stack $stack `
                #     -Level ($level - 1) `
                #     -PrevPropertyName $prevName

                if ($content -notin $MuteProperty) {
                    Add-Property `
                        -InputObject $stack[$level - 1] `
                        -Name $content `
                        -Value $stack[$level]

                    $prevName = $content
                }

                # $keys[$level] = $content
            }

            End {
                if ($null -ne $tableBuild) {
                    Add-Table `
                        -Stack $stack `
                        -Table $tableBuild `
                        -TableStart $tableStart `
                        -PrevLevel $prevLevel `
                        -PrevName $prevName
                }

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

function Write-MdTreeToHtml {
    Param(
	[Parameter(ValueFromPipeline = $true)]
        [PsCustomObject]
	$InputObject
    )

    Write-Output "<ul class=""contains-task-list"">"

    $properties = $InputObject.PsObject.Properties `
    	| where { $_.MemberType -eq 'NoteProperty' } `
	| where { $_.Name.ToLower() -ne 'complete' }

    foreach ($prop in $properties) {
	$value = $prop.Value
	$actionItem = 'complete' -in $value.PsObject.Properties.Name

	Write-Output @(if ($actionItem) {
	    "<li class=""task-list-item""><input type=""checkbox"">$($prop.Name)"
	}
	else {
            "<li>$($prop.Name)"
	})
            
	Write-MdTreeToHtml $value
        Write-Output "</li>"
    }

    Write-Output "</ul>"
}

