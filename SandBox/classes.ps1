enum alignment {
  Left = 0
  Right
  Center
}

class column {
  [string]$FieldName
  [string]$Label
  [int]$Width #Percentage
  [alignment]$Align = [alignment]::Left


  column(
    [string]$FieldName,
    [string]$Label,
    [int]$Width
  ) {
    $this.FieldName = $FieldName
    $this.Label = $Label
    $this.Width = $Width
  }
  
  column(
    [string]$FieldName,
    [string]$Label,
    [int]$Width,
    [alignment]$Align
  ) {
    $this.FieldName = $FieldName
    $this.Label = $Label
    $this.Width = $Width
    $this.Align = $Align
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
  $runspace
  [powershell]$session
  [Int32]$X = $Host.UI.RawUI.CursorPosition.X
  [Int32]$Y = $Host.UI.RawUI.CursorPosition.Y
  [bool]$running = $false

  $Spinners = @{
    "Circle" = @{
      "Frames" = @("◜", "◠", "◝", "◞", "◡", "◟")
      "Sleep"  = 50
    }
    "Dots"   = @{
      "Frames" = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷", "⣿")
      "Sleep"  = 50
    }
    "Line"   = @{
      "Frames" = @("▰▱▱▱▱▱▱", "▰▰▱▱▱▱▱", "▰▰▰▱▱▱▱", "▰▰▰▰▱▱▱", "▰▰▰▰▰▱▱", "▰▰▰▰▰▰▱", "▰▰▰▰▰▰▰", "▰▱▱▱▱▱▱")
      "Sleep"  = 50
    }
    "Square" = @{
      "Frames" = @("⣾⣿", "⣽⣿", "⣻⣿", "⢿⣿", "⡿⣿", "⣟⣿", "⣯⣿", "⣷⣿", "⣿⣾", "⣿⣽", "⣿⣻", "⣿⢿", "⣿⡿", "⣿⣟", "⣿⣯", "⣿⣷")
      "Sleep"  = 50
    }
    "Bubble" = @{
      "Frames" = @("......", "o.....", "Oo....", "oOo...", ".oOo..", "..oOo.", "...oOo", "....oO", ".....o", "....oO", "...oOo", "..oOo.", ".oOo..", "oOo...", "Oo....", "o.....", "......")
      "Sleep"  = 50
    }
    "Arrow"  = @{
      "Frames" = @("≻    ", " ≻   ", "  ≻  ", "   ≻ ", "    ≻", "    ≺", "   ≺ ", "  ≺  ", " ≺   ", "≺    ")
      "Sleep"  = 50
    }
    "Pulse"  = @{
      "Frames" = @("◾", "◾", "◼️", "◼️", "⬛", "⬛", "◼️", "◼️")
      "Sleep"  = 50
    }
  }

  Spinner(
    [string]$type = "Dots"
  ) {
    
    $this.Spinner = $this.Spinners[$type]
  }

  Spinner(
    [string]$type = "Dots",
    [int]$X,
    [int]$Y
  ) {
    $this.Spinner = $this.Spinners[$type]
    $this.X = $X
    $this.Y = $Y
  }

  [void] Start(
    [string]$label = "Loading..."
  ) {
    $this.running = $true
    $this.statedata = [System.Collections.Hashtable]::Synchronized([System.Collections.Hashtable]::new())
    $this.runspace = [runspacefactory]::CreateRunspace()
    $this.statedata.offset = ($this.Spinner.Frames | Measure-Object -Property Length -Maximum).Maximum
    $ThemedFrames = @()
    $this.Spinner.Frames | ForEach-Object {
      $ThemedFrames += gum style $_ --foreground $($Theme["brightPurple"]) 
    }
    $this.statedata.Frames = $ThemedFrames
    $this.statedata.Sleep = $this.Spinner.Sleep
    $this.statedata.label = $label 
    $this.statedata.X = $this.X
    $this.statedata.Y = $this.Y
    $this.runspace.Open()
    $this.Runspace.SessionStateProxy.SetVariable("StateData", $this.StateData)
    $sb = {
      [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
      [system.Console]::CursorVisible = $false
      $X = $StateData.X
      $Y = $StateData.Y
    
      $Frames = $statedata.Frames
      $i = 0
      while ($true) {
        [System.Console]::setcursorposition($X, $Y)
        # $text = "$([char]27)[35m$([char]27)[50m$($Frames[$i])$([char]27)[0m"  
        $text = $Frames[$i]    
        [system.console]::write($text)
        [System.Console]::setcursorposition(($X + $statedata.offset) + 1, $Y)
        [system.console]::write($statedata.label)
        $i = ($i + 1) % $Frames.Length
        Start-Sleep -Milliseconds $Statedata.Sleep
      }
    }
    $this.session = [powershell]::create()
    $null = $this.session.AddScript($sb)
    $this.session.Runspace = $this.runspace
    $null = $this.session.BeginInvoke()
  }

  [void] SetLabel(
    [string]$label
  ) {
    [System.Console]::setcursorposition(($this.X + $this.statedata.offset) + 1, $this.Y)
    [system.console]::write("".PadLeft($this.statedata.label.Length, " "))
    $this.statedata.label = $label
    # Redraw the label to avoid flickering
    [System.Console]::setcursorposition(($this.X + $this.statedata.offset) + 1, $this.Y)
    [system.console]::write($label)
  }

  [void] Stop() {
    if ($this.running -eq $true) {
      $this.running = $false
      $this.session.Stop()
      $this.runspace.Close()
      $this.runspace.Dispose()
    } 
  }
}

$Theme = @{
  "background"   = "#272935"
  "black"        = "#272935"
  "blue"         = "#BD93F9"
  "brightBlack"  = "#555555"
  "brightBlue"   = "#BD93F9"
  "brightCyan"   = "#8BE9FD"
  "brightGreen"  = "#50FA7B"
  "brightPurple" = "#FF79C6"
  "brightRed"    = "#FF5555"
  "brightWhite"  = "#FFFFFF"
  "brightYellow" = "#F1FA8C"
  "cyan"         = "#6272A4"
  "foreground"   = "#F8F8F2"
  "green"        = "#50FA7B"
  "purple"       = "#6272A4"
  "red"          = "#FF5555"
  "white"        = "#F8F8F2"
  "yellow"       = "#FFB86C"
}
