﻿$include = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) 

. "$include\visuals.ps1"
. "$include\classes.ps1"
. "$include\tools.ps1"

$script:fields = Get-Content $env:USERPROFILE\.config\.wingetposh\locals.json | ConvertFrom-Json

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$env:GUM_CHOOSE_SELECTED_BACKGROUND = "22"
$env:GUM_CHOOSE_SELECTED_FOREGROUND = "#ffffff"


$sources = @{
  "winget" = "winget"
  "scoop"  = "scoop"
}

function Get-FieldBAseNAme {
  param(
    [string]$name
  )
  $base = $script:fields.psobject.Properties | Where-Object { $_.Value -eq $name }
  if ($base.count -eq 1) {
    $BaseName = $base.Name
  }
  else {
    $BaseName = ($base | Where-Object { $_.Name.StartsWith("Search") }).Name
  }
  
  return $baseFields[$BaseName]
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
  
  $Session, $runspace = Open-Spinner -label "Loading Packages List" -type "Dots"
  
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
    Close-Spinner -session $Session -runspace $runspace
    gum style --border "rounded" --width $width "$title`n$header" --border-foreground $($Theme["purple"])
    $c = $choices | gum filter  --no-limit  --height $height --indicator "👉 " --placeholder "Search in the list" --prompt.foreground $($Theme["yellow"]) --prompt "🔎 "
    $choices2 = @()
    ($choices -split '\n') | ForEach-Object {
      $temp = $_ -replace [char]27,"@"
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
  if ($session) {
    Close-Spinner -session $Session -runspace $runspace
  } 
  if($uninstall) {
    uninstallPackages -packages $packages
  }

  if($update) {
    updatePackages -packages $packages
  }
  return $packages | Select-Object -Property * -ExcludeProperty Available
}

function installPackages {
  param(
    [package[]]$packages
  )
  $packages | ForEach-Object {
    $Session, $runspace = Open-Spinner -label "Installing $($_.Name)" -type "Dots"
    $command = "winget install --id $($_.Id)"
    Invoke-Expression $command | Out-Null
    Close-Spinner -session $Session -runspace $runspace
  }
}

function uninstallPackages {
  param(
    [package[]]$packages
  )
  $packages | ForEach-Object {
    $Session, $runspace = Open-Spinner -label "Uninstalling $($_.Name)" -type "Dots"
    $command = "winget uninstall --id $($_.Id)"
    Invoke-Expression $command | Out-Null
    Close-Spinner -session $Session -runspace $runspace
  }
}

function updatePackages {
  param(
    [package[]]$packages
  )
  $packages | ForEach-Object {
    $Session, $runspace = Open-Spinner -label "Unpdating $($_.Name)" -type "Dots"
    $command = "winget upgrade --id $($_.Id)"
    Invoke-Expression $command | Out-Null
    Close-Spinner -session $Session -runspace $runspace
  }
}

function Find-WGPackage {
  param(
    [string]$query = $null,
    [string]$source = $null,
    [switch]$install = $false
  )
  
  $SearchParams = @{}
  $Y = $host.ui.rawui.CursorPosition.Y 
  $buffer = gum style "Enter search query" --border "rounded" --width ($Host.UI.RawUI.BufferSize.Width - 2) --border-foreground $($Theme["purple"])
  $buffer | ForEach-Object {
    [System.Console]::write($_)
  }
  
  if (-not $query) {
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
    $Session, $runspace = Open-Spinner -label "Searching for $title in $source" -type "Dots"
    $queries = $query.Split(",")
    $packages = @()
    $queries | ForEach-Object {
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
    $buffer = gum style "No query specified" --border "rounded" --width ($Host.UI.RawUI.BufferSize.Width - 2) --foreground "#FF0000"
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
    Close-Spinner -session $Session -runspace $runspace
    $width = $Host.UI.RawUI.BufferSize.Width - 2
    $height = $Host.UI.RawUI.BufferSize.Height - 6
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
  else {
    Close-Spinner -session $Session -runspace $runspace
  }
  if ($install) {
    installPackages -packages $packages
  }


  return $packages | Select-Object -Property * -ExcludeProperty Available
}


# Find-WGPackage -interactive -source "winget" -install
Get-WGPackage -source "winget"
#Update-WGPackage -interactive