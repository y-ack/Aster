#Requires -Version 5.0
using namespace System.Collections.Generic
using namespace System.Management.Automation.Host
using module .\Classes\Widget.psm1
using module .\Classes\Controller.psm1
using module .\Classes\Window.psm1
using module .\Classes\Textbox.psm1


<#
    .SYNOPSIS
    Returns an Aster object containing type properties for constructing Aster Widget objects.
    .DESCRIPTION
    Adds classes from the Classes directory to an object to be exposed to the caller.
    This allows the Aster types to be used without loaded individually in ~using~ statements.
    .EXAMPLE
    $Aster = New-Aster
    $Widget = $Aster.Widget::new()
#>
function New-Aster
{
    begin 
    {
        $Aster = New-Object –TypeName PSObject
        $ClassList = Get-ChildItem .\Classes
    }
    process 
    {
        
        $ClassList | ForEach {
            $Class = $_.BaseName
            try 
            {
                $Aster | Add-Member -MemberType NoteProperty -Name $Class -Value (Invoke-Expression "[$Class]")
            }
            catch #Perhaps forgot to add to this file includes?
            {
                throw [System.TypeLoadException]::new("Aster type " + $_.FullName + " not loaded.")
            }
        }
        return $Aster
    }
}


# Global functions

<#
.SYNOPSIS
    Internal use function for overwriting portions of an existing string
#>
function InsertString 
{
    param
    (
        [Parameter(Position=0)][String]$Destination, 
        [Parameter(Position=1)][String]$Source, 
        [Parameter(Position=2)][int]$Index, 
        [Parameter(Position=3)][int]$Length = $Source.Length
    )
    if ($Length -gt $Source.Length) 
    { 
        $Length = $Source.Length 
    }
    # Form the three sections and combine them again for the final string
    return ($Destination[0..($Index-1)] + 
            $Source.Substring(0,$Length) + 
            $Destination.Substring($Index+$Length)
           ) -join ''
}

<#
    .DESCRIPTION 
    Copy 2D array slices, preserving dimensionality
    If source length exceeds available region in destination, overflow cells are dropped
    
    .PARAMETER Source
    Source array to copy from

    .PARAMETER Destination
    Destination array to copy to

    .PARAMETER [Destination/Source]Index[X/Y]
    Index to start copy from/to.  Similar to normal copy

    .PARAMETER Length[X/Y]
    Dimensions of copy region.  Cells that overflow the destination are ignored
#>
function 2dCopy 
{
    param
    (
        [Parameter(Position=0)][BufferCell[,]]$Source,
        [Parameter(Position=1)][int]$SourceIndexX      = 0,
        [Parameter(Position=2)][int]$SourceIndexY      = 0,
        [Parameter(Position=3)][BufferCell[,]]$Destination,
        [Parameter(Position=4)][int]$DestinationIndexX = 0,
        [Parameter(Position=5)][int]$DestinationIndexY = 0,
        [Parameter(Position=6)][int]$LengthX           = $Source.GetUpperBound(1),
        [Parameter(Position=7)][int]$LengthY           = $Source.GetUpperBound(0)
    )
    if ($Destination.GetUpperBound(1) -lt 0)
    {
        throw [System.Exception]::new("Dimension error: Destination array must have at least 1 row and be rank 2")
    } elseif ($Destination.Rank -ne 2 -or $Source.Rank -ne 2)
    {
        throw [System.RankException]
    }

    if ($DestinationIndexY -lt 0)
    {
        $SourceIndexY -= $DestinationIndexY
        $LengthY += $DestinationIndexY
    }
    if ($DestinationIndexX -lt 0)
    {
        $SourceIndexX -= $DestinationIndexX
        $LengthX += $DestinationIndexX
    }

    [int]$clipX = [Math]::Min([Math]::Min($Destination.GetUpperBound(1) - $DestinationIndexX + 1, 
                                          $LengthX),
                              $Source.GetUpperBound(1)+1
                             )
    [int]$clipY = [Math]::Min([Math]::Min($Destination.GetUpperBound(0) - $DestinationIndexY + 1, 
                                          $LengthY), 
                              $Source.GetUpperBound(0)+1
                             )
    [int]$SourceColumns = $Source.GetUpperBound(1) + 1
    [int]$DestinationColumns = $Destination.GetUpperBound(1) + 1
    [int]$DestinationRowOffset = $DestinationIndexY * $DestinationColumns
    for ([int]$Y = $SourceIndexY; $Y -lt $clipY; $Y++)
    {
        $DestinationLinearIndex = $DestinationRowOffset + ($DestinationColumns * $Y) + $DestinationIndexX
        [Array[,]]::Copy($Source, 
                         $SourceColumns * $Y + $SourceIndexX, 
                         $Destination, 
                         $DestinationLinearIndex, 
                         $ClipX
                        )
    }
}

#region Buffer manipulation functions

function Set-BufferCell
{
    param
    (
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)][BufferCell[,]]$Buffer,
        [Parameter(Mandatory=$True,Position=1)][Int32]$X,
        [Parameter(Mandatory=$True,Position=2)][Int32]$Y,
        [Parameter(Mandatory=$False,Position=3)][char]$Character = ($Buffer[$Y,$X].Character),
        [Parameter(Mandatory=$False,Position=4)][System.ConsoleColor]$ForegroundColor = ($Buffer[$Y,$X].ForegroundColor),
        [Parameter(Mandatory=$False,Position=5)][System.ConsoleColor]$BackgroundColor = ($Buffer[$Y,$X].BackgroundColor)
    )
    if(-not $Character) { $Character = $Buffer[$Y,$X].Character }
    if(-not $ForegroundColor) { $Buffer[$Y,$X].ForegroundColor }
    if(-not $BackgroundColor) { $Buffer[$Y,$X].BackgroundColor }
    $Buffer[$Y,$X] = [BufferCell]::new($Character, $ForegroundColor, $BackgroundColor, [BufferCellType]::Complete)
}
function Set-BufferCells
{
    param
    (
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)][BufferCell[,]]$Buffer,
        [Parameter(Mandatory=$True,Position=1)][Coordinates[]]$Position,
        [Parameter(Mandatory=$False,Position=3)][char]$Character,
        [Parameter(Mandatory=$False,Position=4)][System.ConsoleColor]$ForegroundColor,
        [Parameter(Mandatory=$False,Position=5)][System.ConsoleColor]$BackgroundColor
    )

    # Set-BufferCell can't lookup current value if a property exists but is e.g. Null
    # Clean up for elegance?  Add more combinations for optimization?  TODO.
    $Position | ForEach-Object { 
        if ($Character)
        {
            Set-BufferCell $Buffer $_.X $_.Y -Character $Character
        }
        if ($ForegroundColor)
        {
            Set-BufferCell $Buffer $_.X $_.Y -ForegroundColor $ForegroundColor
        }
        if ($BackgroundColor)
        {
            Set-BufferCell $Buffer $_.X $_.Y -ForegroundColor $Buffer[$_.Y,$_.X].ForegroundColor -BackgroundColor $BackgroundColor
        }
    }
}

function Set-BufferRow
{
    param
    (
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)][BufferCell[,]]$Buffer,
        [Parameter(Mandatory=$True,Position=1)][UInt32]$Row,
        [Parameter(Mandatory=$False,Position=2)][char]$Character = $null,
        [Parameter(Mandatory=$False,Position=3)][System.ConsoleColor]$ForegroundColor = $null,
        [Parameter(Mandatory=$False,Position=4)][System.ConsoleColor]$BackgroundColor = $null
    )
    
    for ([int]$i = 0; $i -le $Buffer.GetUpperBound(1); $i++)
    {
        Set-BufferCell $Buffer $i $Row $Character $ForegroundColor $BackgroundColor
    }
}

#endregion

function New-CoordinatesPair
{
    param
    (
        [Parameter(Mandatory=$True,Position=1)][Int[]]$Range1,
        [Parameter(Mandatory=$True,Position=2)][Int[]]$Range2
    )
    [Coordinates[]]$Pairs = [Coordinates[]]::new(0)
    
    # Describe the combinations of these ranges as an array of coordinates
    $Range1|%{$y=$_;$Range2|%{$Pairs+=[Coordinates]::new($_,$y)}}
    return $Pairs
}
