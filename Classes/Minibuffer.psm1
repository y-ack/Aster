using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Textbox.psm1

class Minibuffer : Textbox
{
    [bool]$Active = $false
    [bool]$CanFocus = $true

    Minibuffer([UInt32]$X, [UInt32]$Y, [UInt32]$Width)
    {
        $this.Position = [Rectangle]::new($X, $Y, $X + $Width, $Y + 2)
        $this.GUID = New-Guid
    }

    [void]HandleKey([ConsoleKeyInfo]$Key, [guid]$focused)
    {
        if ($this.Active)
        {

            if ($Key.Key -eq 'Enter')
            {
                $this.Lines = "(" + (Invoke-Expression $this.Lines[0]) + ")"
                $this.Active = $false
            } elseif ($Key.KeyChar -ge ' ' -and $Key.KeyChar -le 126)
            {
                $this.Lines[$this.Lines.length - 1] += $Key.KeyChar
            } elseif ($Key.Key -eq 'Backspace' -and $this.Lines[$this.Lines.length - 1].Length -gt 0)
            {
                $CLine = $this.Lines[$this.Lines.length - 1]
                $this.Lines[$this.Lines.length - 1] = $CLine.Remove($Cline.Length - 1,1)
            }
        }

        if ($Key.Key -eq 'X' -and $Key.Modifiers -match "Alt")
        {
            $this.Active = $true
            $this.Lines = @("")
        } elseif ($Key.Key -eq 'G' -and $Key.Modifiers -match "Alt")
        {
            $this.Active = $false
            $this.Lines = @("canceled")
        }
    }

    [void]Background([guid]$focused)
    {
        if($this.Active)
        {
            $this.HighlightRow(0, [ConsoleColor]::White, [ConsoleColor]::DarkGray)
        } else
        {
            $this.HighlightRow(0, [ConsoleColor]::White, [ConsoleColor]::Black)
        }

        ForEach ($Child in $this.Children) {
            $Child.Background($focused)
        }
    }

}