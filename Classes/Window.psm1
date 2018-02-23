using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Widget.psm1

class Window : Widget
{
    [Hashtable]$WindowCharacter = 
    @{
        TopLeft     = '╔' #┌╔
        Top         = '═' #─═
        TopRight    = '╗' #┐╗
        Left        = '║' #│║
        Right       = '║' #│║
        BottomLeft  = '╚' #└╚
        Bottom      = '═' #─═
        BottomRight = '╝' #┘╝
    }
    [UInt16]$Priority
    [String]$Title
    [String]$TitleFormat = "<{1}{0}" #{1}:$WindowCharacter.Top,{0}:$Title

    [UInt32]$ScrollPosition = 0
    [Boolean]$ShowScrollbar
    [Boolean]$Autoscroll

    [Boolean]$CanFocus = $false
    [Boolean]$ContainsFocusedWidget = $false
    [ConsoleColor]$HighlightColor = [ConsoleColor]::Blue

    [int]GetInnerWidth()
    {
        return $this.GetWidth() - [int]$this.ShowScrollbar - 2
    }

    Window([UInt32]$X, [UInt32]$Y, [UInt32]$Width, [UInt32]$Height, [String]$Title = "Untitled")
    {
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + $Height)
        $this.Title = $Title
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
    }
    Window([UInt32]$X, [UInt32]$Y, [UInt32]$Width, [UInt32]$Height, [String]$Title = "Untitled", [Bool]$ShowScrollbar, [Bool]$Autoscroll)
    {
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + $Height)
        $this.Title = $Title
        $this.GUID = New-Guid
        $this.Autoscroll = $Autoscroll
        $this.ShowScrollbar = $ShowScrollbar
        $this.Children = [List[Widget]]::new()
    }
    Window([Rectangle]$Position, [String]$Title = "Untitled", [Bool]$ShowScrollbar, [Bool]$Autoscroll)
    {
        $this.Position = $Position
        $this.Title = $Title
        $this.GUID = New-Guid
        $this.Autoscroll = $Autoscroll
        $this.ShowScrollbar = $ShowScrollbar
        $this.Children = [List[Widget]]::new()
    }

    [BufferCell[,]]GetBufferCellArray() 
    {
        [String[]]$BufferLines = $this.GetTopBorder()
        for($i = 1; $i -lt $this.GetHeight() - 1; $i++)
        {
            $BufferLines += $this.GetBodySpan()
        }
        $BufferLines += $this.GetBottomBorder()

        $Buffer = $global:Host.UI.RawUI.NewBufferCellArray($BufferLines, $this.BorderColor, $this.BackgroundColor)
        $this.CopyChildBuffers($Buffer)
        return $Buffer
    }

    [String]GetTopBorder()
    {
        $TopBorder = $this.WindowCharacter["TopLeft"] + `
            ($this.WindowCharacter["Top"] * ($this.GetWidth() - 2)) + `
            $this.WindowCharacter["TopRight"]
        [String]$TitleString = $this.TitleFormat -f $this.Title,$this.WindowCharacter.Top
        $TopBorder = InsertString $TopBorder $TitleString 1 ($this.GetWidth() - 2)
        return $TopBorder
    }
    [String]GetBottomBorder()
    {
        $BottomBorder = ($this.WindowCharacter["BottomLeft"] + `
            ($this.WindowCharacter["Bottom"] * ($this.GetWidth() - 2)) + `
            $this.WindowCharacter["BottomRight"])
        return $BottomBorder
    }
    [String]GetBodySpan()
    {
        return $this.WindowCharacter["Left"] + " " * $this.GetInnerWidth() + $this.WindowCharacter["Right"]
    }

    [void]HandleKey([ConsoleKeyInfo]$Key, [guid]$focused)
    {
        $this.ContainsFocusedWidget = $true
        if ($this.Children.Count -gt 0)
        {
            $this.Children[$this.SelectFocusedChild($focused)].HandleKey($Key, $focused)
        }
    }

    [void]Background([guid]$focused)
    {
        ForEach ($Child in $this.Children) {
            $Child.Background($focused)
        }
    }

}