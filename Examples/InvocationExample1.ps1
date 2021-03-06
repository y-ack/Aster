﻿using module ..\..\Aster\
using namespace System.Management.Automation.Host

$Aster = New-Aster

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

$window = $Aster.Window::new(0,0,35,16, "My Window")

$textbox = $Aster.Textbox::new(1,1,33,14,$text)
4..10 | %{ $textbox.HighlightRow($_, [ConsoleColor]::Green, [ConsoleColor]::Black) }

$window.AddWidget($textbox)

$origin = [Coordinates]::new(0,0)
$host.ui.RawUI.SetBufferContents($origin, $window.GetBufferCellArray())