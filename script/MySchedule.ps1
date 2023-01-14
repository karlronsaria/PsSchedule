# # todo
# - [ ] test
function Find-MyTree {
    Param(
        [ArgumentCompleter({
            $default =
                cat $PsScriptRoot\..\res\default.json `
                | ConvertFrom-Json
            $path = $default.SearchDirectory
            return (dir $path -Directory).Name
        })]
        [String]
        $Subdirectory,

        [String[]]
        $Tag,

        [ValidateSet('Print', 'Tree', 'Cat', 'Open')]
        [String]
        $Mode = 'Print',

        [String]
        $Directory = $( `
            (cat $PsScriptRoot\..\res\default.json `
                | ConvertFrom-Json).SearchDirectory `
        ),

        [Int]
        $DepthLimit = -1
    )

    $settings = cat $PsScriptRoot\..\res\default.json | ConvertFrom-Json
    $RotateProperties = $settings.RotateSubtreeOnProperties
    $IgnoreSubdirectory = $settings.IgnoreSubdirectory
    $path = Join-Path (Join-Path $Directory $Subdirectory) '*.md'

    $dir = $path `
        | Get-ChildItem `
            -Recurse `
        | where {
            $_.FullName -notlike "*$IgnoreSubdirectory*"
        }

    if ($Mode -in @('Cat', 'Open')) {
        if ($null -eq $Tag) {
            switch ($Mode) {
                'Cat' {
                    return $dir | cat
                }

                'Open' {
                    return "Cannot run command indiscriminately on all files"
                }
            }
        }

        $sls = @()

        foreach ($subtag in $Tag) {
            $sls = @(
                $dir `
                    | Select-String "- tag\:.*$subtag"
            )

            $sls += @(
                $dir `
                    | Select-String "- tag\:\s*$" -Context 0, 99 `
                    | where {
                        $_.Context.PostContext `
                            -match "^\s*-\s*[^:]*$subtag[^:]*$"
                    }
            )
        }

        if ($sls.Count -eq 0) {
            return "No files found"
        }

        switch ($Mode) {
            'Cat' {
                return dir $sls.Path | cat
            }

            'Open' {
                $settings =
                    cat "$PsScriptRoot\..\res\default.json" `
                        | ConvertFrom-Json

                $OpenCommand = $settings.OpenCommand

                foreach ($item in $sls) {
                    Invoke-Expression `
                        "$OpenCommand $($item.Path) +$($item.LineNumber)"
                }

                return $sls
            }
        }
    }

    $tree = $dir `
        | Get-Content `
        | Get-MarkdownTable `
            -DepthLimit $DepthLimit

    function Find-Tag {
        Param(
            [String[]]
            $Haystack,

            [String[]]
            $Needle
        )

        $found = $false

        foreach ($subneedle in $Needle) {
            $found = $found -or $subneedle -in $Haystack

            if ($found) {
                break
            }
        }

        $found
    }

    if ($null -ne $Tag -and $Tag.Count -gt 0) {
        $tree = $tree `
            | Find-Subtree `
                -PropertyName tag `
            | where {
                $subtreeTags = $_.tag.ToLower().Split(',').Trim()

                Find-Tag `
                    -Haystack $Tag.ToLower() `
                    -Needle $subtreeTags
            }
    }

    $tree = $tree | Get-SubtreeRotation `
        -RotateProperty $RotateProperties `

    $tree = switch ($Mode) {
        'Tree' {
            $tree
        }

        'Print' {
            $tree | Write-MarkdownTree
        }
    }

    return $tree
}

# # todo
# - [ ] test
function Get-MySchedule {
    Param(
        [ArgumentCompleter({
            $default =
                cat $PsScriptRoot\..\res\default.json `
                | ConvertFrom-Json
            $path = $default.ScheduleDirectory
            return (dir $path -Directory).Name
        })]
        [String]
        $Subdirectory,

        [ValidateSet('Schedule', 'Open', 'Cat', 'Tree')]
        [String]
        $Mode = 'Schedule',

        [String[]]
        $Pattern,

        [Alias('Date')]
        [ArgumentCompleter({
            $date = Get-Date
            (@(0 .. 62) + @(-61 .. -1)) | foreach {
                Get-Date ($date.AddDays($_)) -Format 'yyyy_MM_dd'
            }
        })]
        [String]
        $StartDate,

        [String]
        $Directory = $( `
            (cat $PsScriptRoot\..\res\default.json `
                | ConvertFrom-Json).ScheduleDirectory `
        ),

        [String]
        $Extension = $( `
            (cat $PsScriptRoot\..\res\default.json `
                | ConvertFrom-Json).ScheduleExtension `
        ),

        [Switch]
        $NoConfirm

        # todo
        # - [ ] WhatIf
    )

    function Get-NewDirectoryPath {
        Param(
            [String]
            $Directory,

            [String]
            $Subdirectory,

            [String]
            $DefaultSubdirectory,

            [String]
            $Extension
        )

        $path = if ($Subdirectory) {
            Join-Path $Directory $Subdirectory
        }
        elseif ($DefaultSubdirectory) {
            Join-Path $Directory $DefaultSubdirectory
        }
        else {
            $Directory
        }

        if ($Extension) {
            $path = Join-Path $path $Extension
        }

        return $path
    }

    function Get-ScheduleObject {
        Param(
            [Object[]]
            $File,

            [Object[]]
            $JsonFile,

            [String]
            $StartDate,

            [PsCustomObject]
            $Default,

            [String]
            $DefaultsFileName
        )

        $IgnoreSubdirectory = (cat "$PsScriptRoot\..\res\default.json" `
            | ConvertFrom-Json).IgnoreSubdirectory

        $schedule =
            Get-ChildItem `
                -Path $File `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Get-Content `
            | Get-Schedule `
                -StartDate:$StartDate `
                -Default:$Default

        if ($null -ne $JsonFile -and (Test-Path $JsonFile)) {
            $subtables =
                Get-ChildItem `
                    -Path $JsonFile `
                    -Recurse `
                | where {
                    $_.FullName -notlike "*$IgnoreSubdirectory*" `
                    -and `
                    $DefaultsFileName -ne $_.Name.ToLower()
                } | foreach {
                    cat $_ | ConvertFrom-Json
                }

            $schedule = $schedule `
                | Add-Schedule `
                    -Table $subtables `
                    -StartDate:$StartDate
        }

        return $schedule
    }

    . "$PsScriptRoot\ScheduleObject.ps1"

    $settings = cat $PsScriptRoot\..\res\default.json | ConvertFrom-Json
    $DefaultsFileName = $settings.ScheduleDefaultsFile
    $OpenCommand = $settings.OpenCommand
    $RotateProperties = $settings.RotateSubtreeOnProperties
    $IgnoreSubdirectory = $settings.IgnoreSubdirectory
    $DefaultSubdirectory = $settings.ScheduleDefaultSubdirectory

    $DefaultSubdirectory = switch ($Mode) {
        'Cat' { '' }
        'Open' { '' }
        'Tree' { '' }
        'Schedule' { $DefaultSubdirectory }
    }

    $path = Get-NewDirectoryPath `
        -Directory $Directory `
        -Subdirectory $Subdirectory `
        -DefaultSubdirectory $DefaultSubdirectory

    if (-not (Test-Path $path)) {
        return @()
    }

    $files = Join-Path $path $Extension
    $defaultsPath = Join-Path $path $DefaultsFileName

    $defaults = if ((Test-Path $defaultsPath)) {
        cat $defaultsPath | ConvertFrom-Json
    } else {
        $null
    }

    $jsonFiles = Join-Path $path "*.json"

    if ($null -ne $Pattern -and $Pattern.Count -gt 0) {
        $files = $Pattern | foreach {
            dir $files `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Select-String $_ `
            | sort -Property Path -Unique
        }

        $jsonFiles = $Pattern | foreach {
            dir $jsonFiles `
                -Recurse `
            | where {
                $_.FullName -notlike "*$IgnoreSubdirectory*"
            } `
            | Select-String $_ `
            | sort -Property Path -Unique
        }

        if ($Mode -eq 'Open') {
            foreach ($sls in (@($files) + @($jsonFiles))) {
                Invoke-Expression `
                    "$OpenCommand $($sls.Path) +$($sls.LineNumber)"
            }

            Write-Output $files
            Write-Output $jsonFiles
            return
        }

        if ($null -ne $files) {
            $files = $files.Path
        }

        if ($null -ne $jsonFiles) {
            $jsonFiles = $jsonFiles.Path
        }
    }

    if ($Mode -eq 'Open') {
        if ($NoConfirm) {
            Write-Output "Opening all files in"
            Write-Output "  $files"
            Write-Output "  $jsonFiles"
        }
        else {
            Write-Output "This will open all files in"
            Write-Output "  $files"
            Write-Output "  $jsonFiles"
            Write-Output ""
            $confirm = 'n'

            do {
                $confirm = Read-Host "Continue? (y/n)"
            }
            while ($confirm -notin @('n', 'y'))

            if ($confirm -eq 'n') {
                return
            }
        }

        foreach ($file in (dir (@($files) + @($jsonFiles)))) {
            Invoke-Expression `
                "$OpenCommand $file"
        }

        return
    }

    if ($Mode -eq 'Cat') {
        if ($null -ne $files) {
            dir $files | cat
        }

        if ($null -ne $jsonFiles) {
            dir $jsonFiles | cat
        }

        return
    }

    $schedule = Get-ScheduleObject `
        -File:$files `
        -JsonFile:$jsonFiles `
        -StartDate:$StartDate `
        -Default:$defaults `
        -DefaultsFileName:$DefaultsFileName

    switch ($Mode) {
        'Schedule' {
            return $schedule | Write-Schedule
        }

        'Tree' {
            return $schedule `
                | Get-SubtreeRotation `
                    -RotateProperty $RotateProperties `
                | Write-MarkdownTree
        }
    }
}

