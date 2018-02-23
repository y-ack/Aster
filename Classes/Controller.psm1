using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Widget.psm1

class Controller : Widget
{
    [List[Widget]]$AllWidgets
    [int]$focused
    
    Controller()
    {
        $this.Position = [Rectangle]::new(0, 0, (Get-Host).UI.RawUI.WindowSize.Width, (Get-Host).UI.RawUI.WindowSize.Height)
        $this.Children = [List[Widget]]::new()
    }

    [void]Start([scriptblock]$Before = {})
    {
        [console]::CursorVisible=$false
        #$global:Host.UI.RawUI.FlushInputBuffer()
        
        $global:Host.UI.RawUI.SetBufferContents([Coordinates]::new(0,0), $this.GetBufferCellArray())
        [System.ConsoleKeyInfo]$Key = [System.ConsoleKeyInfo]::new(0,'Process',0,0,0)
#        $BackgroundUpdate =  New-Object Timers.Timer
#        $BackgroundUpdate.Interval = 1000
#        Register-ObjectEvent -InputObject $BackgroundUpdate -EventName elapsed –SourceIdentifier BackgroundUpdate -Action {$this.CallChildren()}
        do
        {
            $Before.Invoke()

            if ([console]::KeyAvailable)
            {
                $Key = [console]::ReadKey($true)
                if ($Key.Key -eq 'Tab' <#-and $Key.Modifiers -match "Control"#>)
                {
                    # We might not actually have any widgets that can take focus...
                    if($this.AllWidgets.Find({$args[0].CanFocus -eq $true}))
                    {
                        [int]$maybenext = $this.AllWidgets.FindIndex($this.focused + 1, $this.AllWidgets.Count - $this.focused - 1, {$args[0].CanFocus -eq $true})
                        $this.focused = if ($maybenext -ge 0) {$maybenext} else {$this.AllWidgets.FindIndex(0, $this.focused + 1, {$args[0].CanFocus -eq $true})}
                        write-host $this.focused
                    }
                } else
                {
                    $FocusedGuid = $this.AllWidgets[$this.focused].guid
                    $this.Children[$this.SelectFocusedChild($FocusedGuid)].HandleKey($Key, $FocusedGuid)
                }
            }

            $this.CallChildren()

            $global:Host.UI.RawUI.SetBufferContents([Coordinates]::new(0,0), $this.GetBufferCellArray())
        } while ($Key.Key -ne 'Escape')
        [console]::CursorVisible=$true
#        $BackgroundUpdate.Dispose()
    }

    [void]CallChildren()
    {
        $this.Children | Foreach-Object {
            $_.Background($this.AllWidgets[$this.focused].guid)
        }
    }

    [void]AddWidget([Widget[]]$Widgets, [bool]$Focus = $false)
    {
        foreach ($Widget in $Widgets)
        {
            if ($this.Children -notcontains $Widget)
            {
                $this.Children.Add($Widget)
                $this.Keys += $Widget.Controls
            }
        }
        $this.AllWidgets = $this.GetChildren()
        if ($Focus) 
        { 
            $this.focused = [int]$this.AllWidgets.FindIndex({$args[0].guid -eq $Widgets[0].guid})
        }
    }
}