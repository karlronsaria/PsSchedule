class TreeBuilder : ICloneable {
    [object] $Value = $null

    TreeBuilder() {}

    TreeBuilder($InputObject) {
        if ($InputObject -is [array]) {
            $this.Value = @($InputObject) |
                ForEach-Object {
                    [TreeBuilder]::new($_)
                }

            return
        }

        if ($InputObject -is [pscustomobject]) {
            $this.Value = [pscustomobject]@{}

            $InputObject.PsObject.Properties |
                Where-Object { $_.MemberType -eq 'NoteProperty' } |
                ForEach-Object {
                    $temp = [TreeBuilder]::new($_.Value)

                    $this.Value | Add-Member `
                        -MemberType 'NoteProperty' `
                        -Name $_.Name `
                        -Value $temp
                }

            return
        }

        $this.Value = $InputObject
    }

    [object] Clone() {
        return [TreeBuilder]::new($this.ToPsCustomObject())
    }

    [TreeBuilder] SetValue($InputObject) {
        $this.Value = $InputObject
        return $this
    }

    static [object] ToPsCustomObject([object] $InputObject) {
        if ($InputObject -is [array]) {
            return @($InputObject) |
                Where-Object { $_ -is [TreeBuilder] } |
                Where-Object { $null -ne $_.Value } |
                ForEach-Object {
                    ([TreeBuilder] $_).ToPsCustomObject()
                }
        }

        if ($InputObject -is [pscustomobject]) {
            $table = [pscustomobject]@{}

            $InputObject.PsObject.Properties |
                Where-Object { $_.MemberType -eq 'NoteProperty' } |
                Where-Object { $_.Value -is [TreeBuilder] } |
                ForEach-Object {
                    $table | Add-Member `
                        -MemberType 'NoteProperty' `
                        -Name $_.Name `
                        -Value ([TreeBuilder] $_.Value).ToPsCustomObject()
                }

            return $table
        }

        if ($InputObject -is [TreeBuilder]) {
            return ([TreeBuilder] $InputObject).ToPsCustomObject()
        }

        return $InputObject
    }

    [object] ToPsCustomObject() {
        return [TreeBuilder]::ToPsCustomObject($this.Value)
    }

    static [object] Unwrap($InputObject) {
        $temp = $InputObject

        if ($temp -is [array]) {
            return @($temp) |
                ForEach-Object {
                    if ($_ -is [TreeBuilder]) {
                        $_.Value
                    }
                    else {
                        $_
                    }
                }
        }

        if ($temp -is [pscustomobject]) {
            $table = [pscustomobject]@{}

            $temp.PsObject.Properties |
                Where-Object { $_.MemberType -eq 'NoteProperty' } |
                ForEach-Object {
                    $value =
                        if ($_ -is [TreeBuilder]) {
                            $_.Value
                        }
                        else {
                            $_
                        }

                    $table | Add-Member `
                        -MemberType 'NoteProperty' `
                        -Name $_.Name `
                        -Value $value
                }

            return $table
        }

        if ($temp -is [TreeBuilder]) {
            return $temp.Value
        }

        return $temp
    }

    [object] ForEach([scriptblock] $Query) {
        $ptr = $this

        while ($ptr -is [TreeBuilder]) {
            $ptr = $ptr.Value
        }

        # return @($this.Value) |
        return @($ptr) |
            ForEach-Object $Query |
            ForEach-Object {
                if ($_ -is [TreeBuilder]) {
                    $_
                }
                else {
                    [TreeBuilder]::new().SetValue($_)
                }
            }
    }

    [object] Where([scriptblock] $Query) {
        $ptr = $this

        while ($ptr -is [TreeBuilder]) {
            $ptr = $ptr.Value
        }

        return @($ptr) |
            Where-Object {
                [TreeBuilder]::ToPsCustomObject($_) |
                    Where-Object $Query
            } |
            ForEach-Object {
                if ($_ -is [TreeBuilder]) {
                    $_
                }
                else {
                    [TreeBuilder]::new().SetValue($_)
                }
            }
    }

    [TreeBuilder] NewLeaf([string] $PropertyName) {
        if ($null -eq $this.Value) {
            $this.Value = [TreeBuilder]::new()
        }

        $this.Value | Add-Member `
            -MemberType NoteProperty `
            -Name $PropertyName `
            -Value $([TreeBuilder]::new())

        return $this.Value.$PropertyName
    }
    
    [TreeBuilder] SetValue([string] $Name, [object] $Value) {
        $ptr = $this

        while ($ptr.Value -is [TreeBuilder]) {
            $ptr = $ptr.Value
        }

        $tree = if ($null -eq $ptr.$Name) {
            $this.NewLeaf($Name)
        }
        else {
            $this.Value.$Name
        }
        
        $temp = if ($Value -isnot [TreeBuilder]) {
            [TreeBuilder]::new($Value)
        }
        else {
            $Value
        }

        $tree.Value = $temp
        return $tree
    }
    
    [TreeBuilder] AddValue([string] $Name, [object] $Value) {
        $ptr = $this

        while ($ptr.Value -is [TreeBuilder]) {
            $ptr = $ptr.Value
        }

        $temp = if ($Value -isnot [TreeBuilder]) {
            [TreeBuilder]::new($Value)
        }
        else {
            $Value
        }

        return $ptr.SetValue($Name, @($ptr.Value.$Name.Value) + @($temp))
    }
}

