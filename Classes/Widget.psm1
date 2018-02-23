using namespace System.Collections.Generic
using namespace System.Management.Automation.Host

class Widget
{
    [Rectangle]$Position
    [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    [System.ConsoleColor]$BackgroundColor = [System.ConsoleColor]::Black
    [System.ConsoleColor]$BorderColor     = [System.ConsoleColor]::Gray
    [List[Widget]]$Children = [List[Widget]]::new()
    # collection of focus-moving keys in this scope
    [Dictionary`2[Char,Func[Bool]]]$Keys
    # keys for this widget; define on inheriting constructors
    [Dictionary`2[Char,Func[Bool]]]$Controls
    [bool]$CanFocus = $false
    [guid]$GUID

    [BufferCell]$BlankChar = [BufferCell]::new(' ', [ConsoleColor]::White, [ConsoleColor]::Black, [BufferCellType]::Complete)

    Widget([UInt32]$X, [UInt32]$Y, [UInt32]$Width, [UInt32]$Height)
    {
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + $Height)
        $this.GUID = New-Guid
    }
    Widget([Rectangle]$Position)
    {
        $this.Position = $Position
        $this.GUID = New-Guid
    }
    Widget([Widget]$Clone)
    {
        $this = $Clone
        $this.GUID = New-Guid
    }
    Widget() # PowerShell 5.1.14393.1944 bug: inheritance requires default constructor
    {
        $this.Position = [Rectangle]::new(0, 0, 0, 0)
        $this.GUID = New-Guid
        $this.Children = [List[Widget]]::new()
    }


    [int]GetWidth(){ return $this.Position.Right - $this.Position.Left }
    [int]GetHeight(){ return $this.Position.Bottom - $this.Position.Top }

    [void]Draw([Coordinates]$Offset, [PSHostRawUserInterface]$HostUI = $global:host.UI.RawUI)
    {
        [Coordinates]$Coord = [Coordinates]::new($Offset.X + $this.Position.Left, $Offset.Y + $this.Position.Top)
        $HostUI.SetBufferContents($Coord, $this.GetBufferCellArray())
    }

    [BufferCell[,]]GetBufferCellArray()
    {
        [BufferCell[,]]$buffer = $global:Host.UI.RawUI.NewBufferCellArray($this.GetWidth(), $this.GetHeight(), $this.BlankChar)
        $this.CopyChildBuffers($buffer)
        return $buffer
    }

    [BufferCell[,]]CopyChildBuffers([BufferCell[,]]$ParentBuffer)
    {
        ForEach ($Child in $this.Children) {
            2dCopy $Child.GetBufferCellArray() 0 0 $ParentBuffer $Child.Position.Left $Child.Position.Top $Child.GetWidth() $Child.GetHeight()
        }
        return $ParentBuffer
    }

    [void]AddWidget([Widget[]]$Widgets)
    {
        foreach ($Widget in $Widgets)
        {
            if ($this.Children -notcontains $Widget)
            {
                $this.Children.Add($Widget)
                $this.Keys += $Widget.Controls
            }
        }
    }

    [List[Widget]]GetChildren()
    {
        [List[Widget]]$RecursiveChildren = [List[Widget]]::new()
        foreach ($Child in $this.Children)
        {
            $RecursiveChildren.Add($Child)
            $RecursiveChildren.AddRange($Child.GetChildren())
        }
        return $RecursiveChildren
    }

    [int]SelectFocusedChild([guid]$Focused)
    {
        $AllChildren = $this.GetChildren()
        [int]$i = $AllChildren.FindIndex({$args[0].guid -eq $Focused})
        for ($i; $i -ge 0; $i--)
        {
            # Match filial widgets with the flattened list to find the next focus "step"
            $F1Child = $this.Children.FindIndex({$args[0].guid -eq $AllChildren[$i].guid})
            if($F1Child -gt -1)
            {
                return $F1Child
            }
        }
        return -1
    }

    [void]AddControls([Dictionary`2[Char,Func[Bool]]]$Controls)
    {
        $this.Controls += $Controls
    }


    [void]HandleKey([ConsoleKeyInfo]$Key, [guid]$focused)
    {
        $this.BorderColor = [ConsoleColor]::Blue
        if ($this.Children.Count -gt 0 -and $this.guid -ne $focused)
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