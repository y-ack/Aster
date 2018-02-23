using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Widget.psm1

class Textbox : Widget
{
    [String[]]$Lines
    [Dictionary`2[UInt32,Tuple[ConsoleColor,ConsoleColor]]]$Highlight = @{}

    Textbox([UInt32]$X, [UInt32]$Y, [UInt32]$Width, [UInt32]$Height, [String[]]$Lines)
    {
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + $Height)
        $this.Lines = $Lines
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
        $this.Highlight = [Dictionary`2[UInt32,Tuple[ConsoleColor,ConsoleColor]]]::new()
    }
    Textbox([Rectangle]$Position, [String[]]$Lines)
    {
        $this.Position = $Position
        $this.Lines = $Lines
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
        $this.Highlight = [Dictionary`2[UInt32,Tuple[ConsoleColor,ConsoleColor]]]::new()
    }
    Textbox()
    {
        $this.Lines = @(" ")
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
        $this.Highlight = [Dictionary`2[UInt32,Tuple[ConsoleColor,ConsoleColor]]]::new()
    }

    [BufferCell[,]]GetBufferCellArray() 
    {
        [BufferCell[,]]$ClippedBuffer = $global:Host.UI.RawUI.NewBufferCellArray([int32]$this.GetWidth(), [int32]$this.GetHeight(), [BufferCell]::new(' ', [ConsoleColor]::White, [ConsoleColor]::Black, [BufferCellType]::Complete))
        if ($this.Lines.Where({$_ -ne ""}).count -gt 0)
        {
            [BufferCell[,]]$Buffer = $global:Host.UI.RawUI.NewBufferCellArray($this.Lines, $this.ForegroundColor, $this.BackgroundColor)
            2dCopy $Buffer 0 0 $ClippedBuffer 0 0 $this.GetWidth() $this.GetHeight()

            for ([int]$Row = 0; $Row -lt $this.Lines.Length; $Row++)
            {
                if($this.Highlight.ContainsKey($Row))
                {
                    Set-BufferRow $ClippedBuffer $Row -ForegroundColor $this.Highlight[$Row].Item1 -BackgroundColor $this.Highlight[$Row].Item2
                }
            }
        }
        return $ClippedBuffer
    }

    [void]HighlightRow([UInt32]$Row, [System.ConsoleColor]$Foreground, [System.ConsoleColor]$Background)
    {
        if ($this.Highlight.ContainsKey($Row))
        {
            $this.Highlight[$Row] = [Tuple[System.ConsoleColor,System.ConsoleColor]]::new($Foreground, $Background)
        } 
        else
        {
            $this.Highlight.Add($Row, [Tuple[System.ConsoleColor,System.ConsoleColor]]::new($Foreground, $Background))
        }
    }

}