Param(
    [Parameter(ValueFromPipeline = $true)]
    [PsCustomObject[]]
    $TableRow,

    [String]
    $NotebookPath
)

Begin {
    function Get-Property {
        Param(
            [Parameter(Position = 0)]
            $InputObject
        )

        if ($InputObject -is [pscustomobject]) {
            return $_.foreach.PsObject.Properties |
                where { $_.MemberType -eq 'NoteProperty' }
        }

        return $InputObject
    }

    $setting = [pscustomobject]@{
        AddendumType = 'sched addendum'
        AddendumFilePattern = 'rule_*.md'
    }

    $addendum = Join-Path $NotebookPath $setting.AddendumFilePattern |
        Get-ChildItem |
        Get-Content |
        Get-MarkdownTree |
        Find-Subtree -PropertyName $setting.AddendumType |
        foreach { $_.$($setting.AddendumType) } |
        Get-NextTree

    $filter = Get-Property $addendum.foreach |
        foreach { $_.Name -replace "``", "" }

    $captionTemplate = Get-Property $addendum.what
}

Process {
    $TableRow |
        foreach -PipelineVariable row { $_ } |
        where -PipelineVariable row {
            $toAdd = $true

            foreach ($subfilter in $filter) {
                $toAdd = $toAdd -and $($_ | foreach { iex $subfilter })
            }

            $toAdd
        } |
        foreach {
            $captures = [regex]::Matches($captionTemplate, "````(?<code>[^``]+)````")

            foreach ($capture in $captures) {
                $replace = $row | foreach { iex $capture.Groups['code'].Value }
                $captionTemplate = $captionTemplate.Replace($capture, $replace)
            }

            $row | Add-Member `
                -MemberType NoteProperty `
                -Name Addendum `
                -Value $captionTemplate

            $row
        }
}

