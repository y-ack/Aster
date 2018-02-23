using module C:\Users\ben\Documents\WindowsPowerShell\Aster\
using namespace System.Management.Automation.Host
using module ..\Classes\Widget.psm1
using module ..\Classes\Textbox.psm1
using module ..\Classes\Field.psm1
using module ..\Classes\Window.psm1
using module ..\Classes\Minibuffer.psm1
using module ..\Classes\Controller.psm1

$Controller = [Controller]::new()

$text = @(
"THE LAST METROID IS IN",
"CAPTIVITY. THE GALAXY",
"IS AT PEACE...",
"",
"I first battled the Metroids",
"on planet Zebes. It was there",
"that I foiled the plans of",
"the space pirate leader",
"Mother Brain to use the",
"creatures to attack",
"galactic civilization..."
)

$Window1 = [Window]::new(0,0,35,16, "My Window")
$Window2 = [Window]::new(40,1,20,8, "Properties")

$MetroidText = [Textbox]::new(1,1,33,14,$text)
4..10 | %{ $MetroidText.HighlightRow($_, [ConsoleColor]::Green, [ConsoleColor]::Black) }

$Window1.AddWidget($MetroidText)

$NameField   = [Field]::new(1,2,16,"Name")
$AuthorField = [Field]::new(1,3,16,"Author")
$DateField   = [Field]::new(1,4,16,"Date")
$Focused  = [Textbox]::new(1,5,16,1,"Focus: ")
$FrameCount  = [Textbox]::new(1,6,16,1,"Frames: ")
$FrameCount | Add-Member -NotePropertyName Frames -NotePropertyValue 0
$script = {$x = $FrameCount; $x.Frames++; $x.Lines = ("Frames: " + $x.Frames);
$y = $Focused; $y.Lines = ("Focus: " + $Controller.focused)}

$Window2.AddWidget($NameField)
$Window2.AddWidget($AuthorField)
$Window2.AddWidget($DateField)
$Window2.AddWidget($Focused)
$Window2.AddWidget($FrameCount)
$Window2.CanFocus = $true

$Window3 = [Window]::new(0,20,35,16, "Wobble?")


$Minibuffer = [Minibuffer]::new(0,49,50)
$FrameCount | Add-Member -NotePropertyName Controller -NotePropertyValue $Controller

$Controller.AddWidget(@($Window1,$Window2,$Window3))
$Controller.AddWidget(@($Minibuffer), $true)
$Controller.Start($script)