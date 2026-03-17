class ScheduleStore : System.ICloneable {
    [string] $Path
    [string] $Extension
    [string[]] $File
    [string[]] $Json
    [string] $DefaultsName
    [string] $IgnorePattern
    [pscustomobject[]] $Default

    hidden ScheduleStore() {}

    ScheduleStore([string] $Path, [string] $Extension, [string] $DefaultsName, [string[]] $Ignores) {
        $this.Path = $Path
        $this.Extension = $Extension
        $this.File = Join-Path $Path $Extension
        $this.Json = Join-Path $Path "*.json"
        $this.DefaultsName = $DefaultsName
        $this.IgnorePattern = "\\($(@($Ignores) -join '|'))\\"

        $this.Default = $Path |
            Join-Path -ChildPath $DefaultsName |
            Where-Object { $_ | Test-Path } |
            Get-Item |
            Get-Content |
            ConvertFrom-Json -Depth 100
    }

    static [ScheduleStore]
    JsonOnly([string] $Path, [string] $Extension, [string] $DefaultsName, [string[]] $Ignores) {
        $temp = [ScheduleStore]::new()
        $temp.Path = $Path
        $temp.Json = Join-Path $Path "$Extension*.json"
        $temp.DefaultsName = $DefaultsName
        $temp.IgnorePattern = "\\($(@($Ignores) -join '|'))\\"

        $temp.Default = $Path |
            Join-Path -ChildPath $DefaultsName |
            Where-Object { $_ | Test-Path } |
            Get-Item |
            Get-Content |
            ConvertFrom-Json -Depth 100

        return $temp
    }

    [object]
    Clone() {
        return [ScheduleStore]::new(
            $this.Path,
            $this.Extension,
            $this.Defaults
        )
    }

    [System.IO.FileInfo[]]
    FileEnumerate() {
        return $this.File |
            Get-ChildItem -Recurse |
            Where-Object {
                $_.FullName -notmatch $this.IgnorePattern
            }
    }

    [System.IO.FileInfo[]]
    JsonEnumerate() {
        return $this.Json |
            Get-ChildItem -Recurse |
            Where-Object {
                $_.FullName -notmatch $this.IgnorePattern `
                -and `
                $_.Name -ne $this.DefaultsName
            }
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]]
    FileGrep([string[]] $Pattern) {
        return @($Pattern) | ForEach-Object {
            $this.FileEnumerate() |
            Select-String -Pattern $_ |
            Sort-Object -Property Path -Unique
        }
    }

    [Microsoft.PowerShell.Commands.MatchInfo[]]
    JsonGrep([string[]] $Pattern) {
        return @($Pattern) | ForEach-Object {
            $this.JsonEnumerate() |
            Select-String -Pattern $_ |
            Sort-Object -Property Path -Unique
        }
    }

    [pscustomobject[]]
    FromJson() {
        return $this.JsonEnumerate() |
            ForEach-Object {
                $_ |
                Get-Content |
                ConvertFrom-Json -Depth 100
            } |
            ForEach-Object {
                if (@($_.PsObject.Properties.Name) -eq @('sched')) {
                    $_ | Get-NextTree
                }
            }
    }

    [ScheduleStore]
    NarrowByPattern([string] $Pattern) {
        $temp = [ScheduleStore] $this.Clone()
        $temp.File = $this.FileGrep().Path
        $temp.Json = $this.JsonGrep().Path
        return $temp
    }
}

function Get-ScheduleStore {
    Param(
        [string[]]
        $Subdirectory,

        [string]
        $Extension,

        [string[]]
        $IgnoreSubdirectories,

        [switch]
        $JsonOnly
    )

    $setting =
        Get-Content "$PsScriptRoot\..\res\setting.json" |
        ConvertFrom-Json

    $DefaultsFileName = $setting.ScheduleDefaultsFile
    $Directory = $setting.ScheduleDirectory

    if (-not $Subdirectory -or ($Subdirectory | ForEach-Object { $_.ToLower() }) -contains 'all') {
        $Subdirectory = Get-ChildItem $Directory -Directory |
            ForEach-Object { $_.Name }
    }

    if (-not $Extension -and -not $JsonOnly) {
        $Extension = $setting.ScheduleExtension
    }

    if (-not $IgnoreSubdirectories) {
        $IgnoreSubdirectories = $setting.IgnoreSubdirectories
    }

    $constructor = if ($JsonOnly) {
        [ScheduleStore]::JsonOnly
    }
    else {
        [ScheduleStore]::new
    }

    $Subdirectory |
    Select-Object -Unique |
    ForEach-Object { Join-Path $Directory $_ } |
    Where-Object { Test-Path $_ } |
    ForEach-Object {
        $constructor.Invoke(
            $_,
            $Extension,
            $DefaultsFileName,
            $IgnoreSubdirectories
        )
    }
}

