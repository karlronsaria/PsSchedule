. "$PsScriptRoot/TreeBuilder.ps1"

<#
.DESCRIPTION
Requires TreeBuilder.ps1
#>

class JsonRecord : ICloneable {
    hidden [System.IO.FileInfo] $File_
    hidden [TreeBuilder] $Haystack_
    hidden [TreeBuilder] $Needle_

    JsonRecord() {
        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name File `
            -Value { $this.File_ }

        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name Haystack `
            -Value { $this.Haystack_ }

        $this | Add-Member `
            -MemberType ScriptProperty `
            -Name Needle `
            -Value { $this.Needle_ }
    }

    [JsonRecord]
    SetFile([System.IO.FileInfo] $File) {
        if (-not $File) {
            return $null
        }

        $temp = $this.Clone()
        $temp.File_ = $File

        $haystack = $File |
            Get-Content |
            ConvertFrom-Json -Depth 100

        $temp.Haystack_ = [TreeBuilder]::new($haystack)
        return $temp
    }

    [JsonRecord]
    ForEach([scriptblock] $Query) {
        $nextHaystack = if (-not $this.Needle_) {
            $this.Haystack_
        }
        else {
            $this.Needle_
        }

        $needle = $nextHaystack.ForEach($Query)

        if ($null -eq $needle) {
            return $null
        }

        $temp = $this.Clone()
        $temp.Needle_ = $needle
        return $temp
    }

    [JsonRecord]
    Where([scriptblock] $Query) {
        $nextHaystack = if (-not $this.Needle_) {
            $this.Haystack_
        }
        else {
            $this.Needle_
        }

        $needle = $nextHaystack.Where($Query)

        if ($null -eq $needle) {
            return $null
        }

        $temp = $this.Clone()
        $temp.Needle_ = $needle
        return $temp
    }

    [JsonRecord]
    SetValue([string] $Name, [object] $Value) {
        $nextHaystack = if (-not $this.Needle_) {
            $this.Haystack_
        }
        else {
            $this.Needle_
        }

        $needle = $nextHaystack.SetValue($Name, $Value)

        if ($null -eq $needle) {
            return $null
        }

        $temp = $this.Clone()
        $temp.Needle_ = $needle
        return $temp
    }

    [JsonRecord]
    AddValue([string] $Name, [object] $Value) {
        $nextHaystack = if (-not $this.Needle_) {
            $this.Haystack_
        }
        else {
            $this.Needle_
        }

        $needle = $nextHaystack.AddValue($Name, $Value)

        if ($null -eq $needle) {
            return $null
        }

        $temp = $this.Clone()
        $temp.Needle_ = $needle
        return $temp
    }

    [object]
    Clone() {
        $temp = [JsonRecord]::new()
        $temp.File_ = $this.File_
        $temp.Haystack_ = $this.Haystack_
        $temp.Needle_ = $this.Needle_
        return $temp
    }

    [string]
    ToJson() {
        return $this.Haystack_.ToPsCustomObject() |
            ConvertTo-Json -Depth 100
    }

    [void]
    WriteBack() {
        $this.ToJson() |
            Out-File -FilePath $this.File_
    }

    [void]
    ForceWriteBack() {
        $this.ToJson() |
            Out-File -FilePath $this.File_ -Force
    }

    static [JsonRecord[]]
    Scan($InputObject) {
        return $InputObject |
            Get-ChildItem -File |
            ForEach-Object {
                [JsonRecord]::new().SetFile($_)
            } |
            Where-Object { $_ }
    }

    static [JsonRecord[]]
    Scan($InputObject, [scriptblock] $Query) {
        return $InputObject |
            Get-ChildItem -File |
            ForEach-Object {
                [JsonRecord]::new().SetFile($_)
            } |
            Where-Object { $_ } |
            ForEach-Object {
                $_.Query($Query)
            }
    }
}

