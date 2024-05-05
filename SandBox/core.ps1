Import-Module "$PSScriptRoot\visuals.ps1" -Force
Import-Module "$PSScriptRoot\classes.ps1" -Force
Import-Module "$PSScriptRoot\tools.ps1" -Force

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$env:GUM_CHOOSE_SELECTED_BACKGROUND = $Theme["green"]
$env:GUM_CHOOSE_SELECTED_FOREGROUND = $Theme["white"]
$env:GUM_FILTER_CURSOR_TEXT_UNDERLINE = 1 #cursor-text.underline


$sources = @{
  "winget" = "winget"
  "scoop"  = "scoop"
}

function Get-FieldLength {
  param(
    [string]$buffer
  )
  $i = 0
  $buffer.ToCharArray() | ForEach-Object {
    $l = [Text.Encoding]::UTF8.GetByteCount($_)
    if ($l -ge 2) {
      $l = $l - 1
    }  
    $i += $l 
  }
  return $i
}

function Get-WGPackage { 
  param(
    [string]$source = $null,
    [switch]$update = $false,
    [switch]$uninstall = $false
  )
  $GetParams = @{}
  if ($source) {
    $GetParams.Add("source", $source)
  }
  
  if ($update -and $uninstall) {
    # TODO: make error message a generic function
    [System.Console]::setcursorposition(0, $Y)
    $Title = gum style " ERROR " --background $($Theme["red"]) --foreground $($Theme["white"]) --bold
    $buffer = gum style "$($Title)`n'-update' & '-uninstall' cannot be used at the same time" --border "rounded" --width ($Host.UI.RawUI.BufferSize.Width - 2) --foreground $($Theme["yellow"])
    $buffer | ForEach-Object {
      [System.Console]::write($_)
    }
    return $null
  }
  $Spinner = [Spinner]::new("Dots")
  $Spinner.Start("Loading Packages List")
  
  $packages = Get-WinGetPackage 

  if ($source) {
    $packages = $packages | Where-Object { $_.Source -eq $source }
  }

  if ($update) {
    $packages = $packages | Where-Object { $_.IsUpdateAvailable -eq $true }
  }
  
  [column[]]$cols = @()
  $cols += [column]::new("Name", "Name", 40)
  $cols += [column]::new("Id", "Id", 40)
  $cols += [column]::new("InstalledVersion", "Version", 17)
  [package[]]$InstalledPackages = @()
  $packages | ForEach-Object {
    $InstalledPackages += [package]::new($_.Name, $_.Id, $_.AvailableVersions, $_.Source, $_.IsUpdateAvailable, $_.InstalledVersion)
  }
  $choices = makeLines -columns $cols -items $InstalledPackages
  $width = $Host.UI.RawUI.BufferSize.Width - 2
  $height = $Host.UI.RawUI.BufferSize.Height - 7
  $title = makeTitle -title "List of Installed Packages" -width $width
  $header = makeHeader -columns $cols
  
  $Spinner.Stop()
  [System.Console]::setcursorposition(0, $Y)
  gum style --border "rounded" --width $width "$title`n$header" --border-foreground $($Theme["purple"])
  
  $c = $choices | gum filter  --no-limit  --height $height --indicator "👉 " --placeholder "Search in the list" --prompt.foreground $($Theme["yellow"]) --prompt "🔎 "
  $choices2 = @()
    ($choices -split '\n') | ForEach-Object {
    $temp = $_ -replace [char]27, "@"
    if ($temp -match '@[\[][\d1,3;]*m') {
      $temp = $temp -replace '@[\[][\d1,3;]*m', ""
    }
    $choices2 += $temp
  }
  $packages = @()
  if ($c) {
    $c | ForEach-Object {
      $index = $choices2.IndexOf($_)
      $packages += $InstalledPackages[$index] #| Select-Object -Property * -ExcludeProperty Available
    }
  }
  Clear-Host
   
  if ($uninstall) {
    uninstallPackages -packages $packages
  }

  if ($update) {
    updatePackages -packages $packages
  }

  # Return choosen packages without the "Available" property
  return $packages | Select-Object -Property * -ExcludeProperty Available
}

function installPackages {
  param(
    [package[]]$packages
  )
  $Spinner = [Spinner]::new("Dots")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Installing $($_.Name)")
    } else {
      $Spinner.SetLabel("Installing $($_.Name)")
    }
    $command = "winget install --id $($_.Id)"
    Invoke-Expression $command | Out-Null
  }
  $Spinner.Stop()
}

function uninstallPackages {
  param(
    [package[]]$packages
  )
  $Spinner = [Spinner]::new("Dots")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Uninstalling $($_.Name)")
    } else {
      $Spinner.SetLabel("Uninstalling $($_.Name)")
    }
    $command = "winget uninstall --id $($_.Id)"
    Invoke-Expression $command | Out-Null
  }
  $Spinner.Stop()
}

function updatePackages {
  param(
    [package[]]$packages
  )
  $Spinner = [Spinner]::new("Dots")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Upgrading $($_.Name)")
    } else {
      $Spinner.SetLabel("Upgrading $($_.Name)")
    }
    $command = "winget upgrade --id $($_.Id)"
    Invoke-Expression $command | Out-Null
  }
  $Spinner.Stop()
}

function Find-WGPackage {
  param(
    [string]$query = $null,
    [string]$source = $null,
    [switch]$install = $false
  )
  [Spinner]$Spinner
  $SearchParams = @{}
  $Y = $host.ui.rawui.CursorPosition.Y 
  $width = $Host.UI.RawUI.BufferSize.Width - 2
  $buffer = gum style "Enter search query" --border "rounded" --width $width --border-foreground $($Theme["purple"])
  $buffer | ForEach-Object {
    [System.Console]::write($_)
  }
  
  if (-not $query -or $null -eq $query) {
    $query = gum input --placeholder "Search for a package" 
    $SearchParams.Add("query", $query)
  }

  if ($source) {
    $SearchParams.Add("source", $source)
  }
  else {
    $source = gum style "every sources" --foreground "#FF0000"
  }
  if ($query) {
    $title = gum style $query --foreground "#00FF00" --bold
    $Spinner = [Spinner]::new("Dots")
    
    $queries = $query.Split(",")
    $packages = @()
    $queries | ForEach-Object {
      if (-not $Spinner.running) {
        $Spinner.start("Searching for $_ in $source")
      } else {
        $Spinner.SetLabel("Searching for $_ in $source")
      }
      $SearchParams["query"] = [string]$_.Trim()
      $packs = Find-WinGetPackage @SearchParams
      $packs | ForEach-Object {
        $packages += $_
      }
    }
    [System.Console]::setcursorposition(0, $Y)
  }
  else {
    [System.Console]::setcursorposition(0, $Y)
    $buffer = gum style "No query specified" --border "rounded" --width $width --foreground $($Theme["red"])
    $buffer | ForEach-Object {
      [System.Console]::write($_)
    }
    return $null
  }
  if ($packages) {
    [column[]]$cols = @()
    $cols += [column]::new("Name", "Name", 40)
    $cols += [column]::new("Id", "Id", 40)
    $cols += [column]::new("Available", "Version", 20)
    [package[]]$InstalledPackages = @()
    $packages | ForEach-Object {
      $InstalledPackages += [package]::new($_.Name, $_.Id, $_.AvailableVersions, $_.Source, $_.IsUpdateAvailable, $_.InstalledVersion)
    }
    $choices = makeLines -columns $cols -items $InstalledPackages
    $Spinner.Stop()
    $height = $Host.UI.RawUI.BufferSize.Height - 7
    [System.Console]::setcursorposition(0, $Y)
    $title = makeTitle -title "Choose Packages to Install" -width $width
    $header = makeHeader -columns $cols
    gum style --border "rounded" --width $width "$title`n$header" --border-foreground $($Theme["purple"]) 
    $c = $choices | gum filter  --no-limit  --height $height --indicator "👉 " --placeholder "Search in the list" --prompt.foreground $($Theme["yellow"]) --prompt "🔎 "
    [package[]]$packages = @()
    if ($c) {
      $c | ForEach-Object {
        $index = ($choices -split '\n').IndexOf($_)
        $packages += $InstalledPackages[$index]
      }
    }
    Clear-Host
  }
  if ($install) {
    installPackages -packages $packages
  }
  if ($Spinner) {
    $Spinner.Stop()
  }
  return $packages | Select-Object -Property * -ExcludeProperty Available
}


# Find-WGPackage -source "winget" -install
# Get-WGPackage -source "winget"
#Update-WGPackage -interactive

# $spinner = [Spinner]::new("Dots")
# $Spinner.start("Loading Packages List")
# Start-Sleep -Seconds 5
# $Spinner.SetLabel("Still Searching...")
# Start-Sleep -Seconds 5

# $Spinner.stop()