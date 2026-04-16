. "$PsScriptRoot/../lib/ScheduleStore.ps1"
. "$PsScriptRoot/../lib/TreeBuilder.ps1"
. "$PsScriptRoot/../lib/JsonRecord.ps1"
. "$PsScriptRoot/ScheduleDateTime.ps1"

<#
.DESCRIPTION
Requires JsonRecord.ps1, ScheduleStore.ps1
#>

# class ScheduleJsonRecord : JsonRecord {
#     [ScheduleJsonRecord] Shelve() {
#         return $this
#     }
# 
#     [ScheduleJsonRecord] Unshelve() {
#         return $this
#     }
# }

function Move-ScheduleItem {
    [CmdletBinding(DefaultParameterSetName = 'GetPath')]
    Param(
        [ArgumentCompleter({
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            if ($FakeBoundParameters.Keys -contains 'Subdirectory') {
                $setting =
                    Get-Content "$PsScriptRoot\..\res\setting.json" |
                    ConvertFrom-Json

                return Get-ScheduleStore `
                    -Subdirectory:$FakeBoundParameters['Subdirectory'] `
                    -Extension '*move-schedule' `
                    -IgnoreSubdirectories $setting.MoveItem.IgnoreSubdirectories `
                    -JsonOnly |
                ForEach-Object {
                    $_.FromJson().what |
                        Where-Object { $_ } |
                        ForEach-Object { "`"$_`"" }
                }
            }

            Get-ScheduleStore `
                -Extension "*move-schedule" `
                -JsonOnly |
            ForEach-Object {
                $_.FromJson().what |
                    Where-Object { $_ } |
                    ForEach-Object { "`"$_`"" }
            }
        })]
        [string]
        $What,

        [Parameter(ParameterSetName = 'ByDayCode')]
        [ValidateSet('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')]
        [string]
        $Day,

        [Parameter(ParameterSetName = 'ByDate')]
        [ArgumentCompleter({
            Param(
                $cmdName,
                $paramName,
                $wordToComplete
            )

            $now = Get-Date

            $dates = (@(0 .. 62) + @(-61 .. -1)) | foreach {
                Get-Date ($now.AddDays($_)) -Format 'yyyy-MM-dd' # Uses DateTimeFormat
            }

            $suggestions = if ($wordToComplete) {
                $dates | where { $_ -like "$wordToComplete*" }
            }
            else {
                $dates
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $dates
            })
        })]
        [string]
        $Date,

        [ArgumentCompleter({
            Param(
                $cmdName,
                $paramName,
                $wordToComplete
            )

            $setting =
                Get-Item "$PsScriptRoot/../res/setting.json" |
                Get-Content |
                ConvertFrom-Json

            $dirs = (Get-ChildItem $setting.ScheduleDirectory -Directory).Name + @('All')

            $suggestions = if ($wordToComplete) {
                $dirs |
                    Where-Object { $_ -like "$wordToComplete*" }
            }
            else {
                $dirs
            }

            return $(if ($suggestions) {
                $suggestions
            }
            else {
                $dirs
            })
        })]
        [string[]]
        $Subdirectory,

        [Parameter(ParameterSetName = 'ByDayCode')]
        [Parameter(ParameterSetName = 'ByDate')]
        [ValidateScript({ $_ -match "\d{4}" })]
        [string]
        $Time
    )

    $setting =
        Get-Content "$PsScriptRoot/../res/setting.json" |
        ConvertFrom-Json

    $stores = Get-ScheduleStore `
        -Subdirectory:$Subdirectory `
        -Extension '*move-schedule' `
        -IgnoreSubdirectories $setting.MoveItem.IgnoreSubdirectories `
        -JsonOnly
        
    if ($PSCmdlet.ParameterSetName -eq 'GetPath') {
        return $stores.JsonEnumerate() |
        Where-Object { $_ }
    }

    if ($PsCmdlet.ParameterSetName -eq 'ByDayCode') {
        $Date = Get-NextDay -Day $Day
    }

    $when = Get-Date `
        -Date $Date `
        -Format "ddd yyyy-MM-dd" # Uses DateTimeFormat

    if ($Time) {
        $when = "${when}-${Time}" # Uses DateTimeFormat
    }

    @($stores) | ForEach-Object {
        $_.JsonEnumerate()
    } | ForEach-Object {
        [JsonRecord]::new().SetFile($_)
    } | Where-Object {
        $_
    } | ForEach-Object {
        $_.ForEach({ $_.sched }).Where([JsonRecord]::NewClosure({ $_.what -like "*$What*" }))
    } | Where-Object {
        $_
    } | ForEach-Object {
        $whenTree = $_.ForEach({ $_.when })
        
        if ($null -ne $when) {
            $_.AddValue('log', $whenTree.Needle.Clone()) |
                Out-Null
                
            $whenTree.Needle.Value = $when
        }
        else {
            $_.AddValue('when', $when) |
                Out-Null
        }
        
        $_.ToJson()
        $_.ForceWriteBack()
    }
}

