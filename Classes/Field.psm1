using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Widget.psm1

class Field : Widget
{
    [string]$Name = ""
    [string]$Value = ""
    [string]$Separator = ": "
    [ConsoleColor]$InputForeground = $this.ForegroundColor
    [ConsoleColor]$InputBackground = $this.BackgroundColor
    [bool]$CanFocus = $true

    Field([UInt32]$X, [UInt32]$Y, [UInt32]$Width, [String]$Name)
    {
        # Put value entry on a new line if there might not be enough space
        [int]$Height = 1
        if ($Name.Length * 2 -gt $Width)
        {
            $Height = 2
        }
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + $Height)

        $this.Name = $Name
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
    }

    [BufferCell[,]]GetBufferCellArray()
    {
        [string[]]$Lines = ""
        if ($this.GetHeight() -eq 1)
        {
            $InputWidth = $this.GetWidth() - ($this.Name + $this.Separator).Length
            $Lines = $this.Name + $this.Separator + $this.GetValueField($InputWidth)
            $inputcells = New-CoordinatesPair -Range2 (($this.Name + $this.Separator).Length..($this.GetWidth()-1)) -Range1 0
        } else
        {
            $Lines = $this.Name + $this.Separator
            $Lines += $this.Value + $this.GetValueField($this.GetWidth())
            $inputcells = New-CoordinatesPair -Range2 (0..($this.GetWidth()-1)) -Range1 1
        }

        [BufferCell[,]]$Buffer = $global:Host.UI.RawUI.NewBufferCellArray($Lines, $this.ForegroundColor, $this.BackgroundColor)

        Set-BufferCells $Buffer $inputcells -ForegroundColor $this.InputForeground -BackgroundColor $this.InputBackground
        $this.CopyChildBuffers($Buffer)
        return $Buffer
    }

    [String]GetValueField([int]$width)
    {
        # actually 'scrolls' when exceeds the width v
        $FormattedValue = -join $this.Value[[Math]::max(0, $this.Value.Length - $width)..($this.Value.Length - 1)]
        $Spaces = "_" * [Math]::max(0, ($width - $FormattedValue.Length))
        return $FormattedValue + $Spaces
    }

    [void]HandleKey([ConsoleKeyInfo]$Key, [guid]$focused)
    {
        $this.InputBackground = [ConsoleColor]::DarkBlue
        if ($Key.KeyChar -ge ' ' -and $Key.KeyChar -le 126)
        {
            $this.Value += $Key.KeyChar
        } elseif ($Key.Key -eq 'Backspace' -and $this.Value.Length -gt 0)
        {
            $this.Value = $this.Value.Remove($this.Value.Length - 1,1)
        }
    }

    [void]Background([guid]$focused)
    {
        if ($this.guid -eq $focused)
        {
            $this.InputBackground = [ConsoleColor]::DarkBlue
        } else
        {
            $this.InputBackground = $this.BackgroundColor
        }
    }

}