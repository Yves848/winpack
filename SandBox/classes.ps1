class column {
  [string]$FieldName
  [string]$Label
  [int]$Width #Percentage

  column(
    [string]$FieldName,
    [string]$Label,
    [int]$Width
  ) {
    $this.FieldName = $FieldName
    $this.Label = $Label
    $this.Width = $Width
  }
}

class package {
  [string]$Name
  [string]$Id
  [string[]]$AvailableVersions
  [string]$Source
  [bool]$IsUpdateAvailable
  [string]$InstalledVersion
  [string]$Available

  package(
    [string]$Name,
    [string]$Id,
    [string[]]$AvailableVersions,
    [string]$Source,
    [bool]$IsUpdateAvailable,
    [string]$InstalledVersion
  ) {
    $this.Name = $Name
    $this.Id = $Id
    $this.AvailableVersions = $AvailableVersions
    $this.Source = $Source
    $this.IsUpdateAvailable = $IsUpdateAvailable
    $this.InstalledVersion = $InstalledVersion
    $this.Available = $AvailableVersions[0]
  }

  package(
    [string]$Name,
    [string]$Id,
    [string]$InstalledVersion
  ) {
    $this.Name = $Name
    $this.Id = $Id
    $this.InstalledVersion = $InstalledVersion
  }
  
  package(
    [string]$Name,
    [string]$Id,
    [string]$InstalledVersion,
    [string]$Available
  ) {
    $this.Name = $Name
    $this.Id = $Id
    $this.InstalledVersion = $InstalledVersion
    $this.Available = $Available
  }
}

class Spinner {
  [hashtable]$Spinner
  [System.Collections.Hashtable]$statedata
  [runspacefactory]$runspace
  [powershell]$session
  [Int32]$X
  [Int32]$Y

  Spinner(
    [string]$type
  ) {
    $this.Spinners = @{
      "Circle" = @{
        "Frames" = @("◜", "◠", "◝", "◞", "◡", "◟")
        "Sleep"  = 50
      }
      "Dots"    = @{
        "Frames" = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷", "⣿")
        "Sleep"  = 50
      }
      "Line"   = @{
        "Frames" = @("▰▱▱▱▱▱▱", "▰▰▱▱▱▱▱", "▰▰▰▱▱▱▱", "▰▰▰▰▱▱▱", "▰▰▰▰▰▱▱", "▰▰▰▰▰▰▱", "▰▰▰▰▰▰▰", "▰▱▱▱▱▱▱")
        "Sleep"  = 50
      }
      "Square" = @{
        "Frames" = @("⣾⣿", "⣽⣿", "⣻⣿", "⢿⣿", "⡿⣿", "⣟⣿", "⣯⣿", "⣷⣿","⣿⣾", "⣿⣽", "⣿⣻", "⣿⢿", "⣿⡿", "⣿⣟", "⣿⣯", "⣿⣷")
        "Sleep"  = 50
      }
      "Bubble" = @{
        "Frames" = @("......","o.....","Oo....","oOo...",".oOo..","..oOo.","...oOo","....oO",".....o","....oO","...oOo","..oOo.",".oOo..","oOo...","Oo....","o.....","......")
        "Sleep"  = 50
      }
      "Arrow"  = @{
        "Frames" = @("≻    ", " ≻   ", "  ≻  ", "   ≻ ", "    ≻","    ≺", "   ≺ ", "  ≺  ", " ≺   ", "≺    ")
        "Sleep"  = 50
      }
      "Pulse"  = @{
        "Frames" = @("◾", "◾", "◼️", "◼️", "⬛", "⬛", "◼️", "◼️")
        "Sleep"  = 50
      }
    }
    $this.Spinner = $this.Spinners[$type]
  }
}

$Theme = @{
  "background" = "#272935"
  "black" = "#272935"
  "blue" = "#BD93F9"
  "brightBlack" = "#555555"
  "brightBlue" = "#BD93F9"
  "brightCyan" = "#8BE9FD"
  "brightGreen" = "#50FA7B"
  "brightPurple" = "#FF79C6"
  "brightRed" = "#FF5555"
  "brightWhite" = "#FFFFFF"
  "brightYellow" = "#F1FA8C"
  "cyan" = "#6272A4"
  "foreground" = "#F8F8F2"
  "green" = "#50FA7B"
  "purple" = "#6272A4"
  "red" = "#FF5555"
  "white" = "#F8F8F2"
  "yellow" = "#FFB86C"
}
