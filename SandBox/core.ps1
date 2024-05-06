Import-Module "$PSScriptRoot\visuals.ps1" -Force
Import-Module "$PSScriptRoot\classes.ps1" -Force
Import-Module "$PSScriptRoot\tools.ps1" -Force

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# GUM dfault environment variables
$env:GUM_FILTER_INDICATOR = "▶ "
$env:GUM_FILTER_INDICATOR_FOREGROUND = $Theme["green"]
$env:BORDER_FOREGROUND = $($Theme["purple"])
$env:GUM_CHOOSE_SELECTED_BACKGROUND = $Theme["green"]
$env:GUM_CHOOSE_SELECTED_FOREGROUND = $Theme["white"]
$env:GUM_FILTER_CURSOR_TEXT_UNDERLINE = 1 #cursor-text.underline

$module = Get-InstalledModule -Name winpack -ErrorAction SilentlyContinue
if (-not $module) {
  $Script:version = "debug"
}
else {
  $Script:version = $module.Version
}


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

function RetrievePackages {
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
    # TODO: #2 make error message a generic function
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

  [package[]]$InstalledPackages = @()
  $packages | ForEach-Object {
    $InstalledPackages += [package]::new($_.Name, $_.Id, $_.AvailableVersions, $_.Source, $_.IsUpdateAvailable, $_.InstalledVersion)
  }
  $Spinner.Stop()
  return $InstalledPackages
}

function ShowPackages {
  param(
    [package[]]$InstalledPackages,
    [switch]$update = $false,
    [switch]$uninstall = $false
  )
  [column[]]$cols = @()
  $cols += [column]::new("Name", "Name", 35)
  $cols += [column]::new("Id", "Id", 35)
  $cols += [column]::new("InstalledVersion", "Version", 17, [Alignment]::Right)
  $cols += [column]::new("Source", "Source", 10)
  
  $choices = makeLines -columns $cols -items $InstalledPackages
  $width = $Host.UI.RawUI.BufferSize.Width - 2
  $height = $Host.UI.RawUI.BufferSize.Height - 7
  if ($update) {
    $title = makeTitle -title "List of Packages to Update" -width $width
  }
  elseif ($uninstall) {
    $title = makeTitle -title "List of Packages to Uninstall" -width $width
  }
  else {
    $title = makeTitle -title "List of Installed Packages" -width $width
  }
  $header = makeHeader -columns $cols
  
  # $Spinner.Stop()
  [System.Console]::setcursorposition(0, $Y)
  $title = gum style --border "rounded" --width ($width) "$title`n$header" --border-foreground $($Theme["purple"])
  GumOutput -text $title
  
  $c = $choices | gum filter  --no-limit  --height $height --placeholder "Search in the list" --prompt.foreground $($Theme["yellow"]) --prompt "🔎 "
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
  # Return choosen packages without the "Available" property
  return $packages #| Select-Object -Property * -ExcludeProperty Available
}

function Get-WGPackage { 
  param(
    [string]$source = $null,
    [switch]$update = $false,
    [switch]$uninstall = $false
  )
  $params = @{}
  if ($source) {
    $params.Add("source", $source)
  }
  if ($update) {
    $params.Add("update", $true)
  }
  if ($uninstall) {
    $params.Add("uninstall", $true)
  }
  $packages = RetrievePackages @params
  if ($packages) {
    $params = $params | Select-Object -Property * -ExcludeProperty source
    $packages = ShowPackages -InstalledPackages $packages @($params) 
  }

  if ($uninstall -eq $true) {
    uninstallPackages -packages $packages
  }

  if ($update -eq $true) {
    updatePackages -packages $packages
  }

  return $packages | Select-Object -Property * -ExcludeProperty Available
}

function installPackages {
  param(
    [package[]]$packages
  )
  $Spinner = [Spinner]::new("Bubble")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Installing $($_.Name)")
    }
    else {
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
  $Spinner = [Spinner]::new("Bubble")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Uninstalling $($_.Name)")
    }
    else {
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
  $Spinner = [Spinner]::new("Bubble")
  $packages | ForEach-Object {
    if (-not $Spinner.running) {
      $Spinner.start("Upgrading $($_.Name)")
    }
    else {
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
  
  if (-not $query -or $null -eq $query) {
    $buffer = gum style "Enter search query" --border "rounded" --width $width
    $buffer | ForEach-Object {
      [System.Console]::write($_)
    }
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
      }
      else {
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
    $buffer = gum style "No query specified" --border "rounded" --width $width --foreground $($Theme["white"]) --border-foreground $($Theme["red"])
    $buffer | ForEach-Object {
      [System.Console]::write($_)
    }
    return $null
  }
  if ($packages) {
   
    [column[]]$cols = @()
    $cols += [column]::new("Name", "Name", 35)
    $cols += [column]::new("Id", "Id", 35)
    $cols += [column]::new("Available", "Version", 17, [Alignment]::Right)
    $cols += [column]::new("Source", "Source", 10)

    [package[]]$InstalledPackages = @()
    $packages | ForEach-Object {
      $InstalledPackages += [package]::new($_.Name, $_.Id, $_.AvailableVersions, $_.Source, $_.IsUpdateAvailable, $_.InstalledVersion)
    }
    $choices = makeLines -columns $cols -items $InstalledPackages
    $height = $Host.UI.RawUI.BufferSize.Height - 7
    [System.Console]::setcursorposition(0, $Y)
    $title = makeTitle -title "Choose Packages to Install" -width $width
    $header = makeHeader -columns $cols
    $Spinner.Stop()
    Clear-Host
    gum style --border "rounded" --width $width "$title`n$header" --border-foreground $($Theme["purple"]) 
    $c = $choices | gum filter  --no-limit  --height $height --placeholder "Search in the list" --prompt.foreground $($Theme["yellow"]) --prompt "🔎 "
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

function Build-Script {
  $first = $true	
  $packages = RetrievePackages -source "winget"
  while ($true) {
    $Selectedpackages = ShowPackages -InstalledPackages $packages
    if ($Selectedpackages) {
      $result = gum style "Choose a script type :" --foreground $($Theme["brightGreen"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
      GumOutput -text $result
      $types = @(
        "Winget",
        "Winpack"
      )
      $type = $types -join "`n" | gum choose
      if ($first) {
        $file = gum input --placeholder "Enter the name of the script (without extension)"
      }
      $index = $types.IndexOf($type)
      switch ($index) {
        0 { 
          $filename = "$file.ps1"
          if (Test-Path -Path $filename) {
            $replace = gum confirm "File already exists, do you want to replace it?" --affirmative "Yes" --negative "No" && $true || $false
            if ($replace) {
              Remove-Item -Path $filename -Force
              $null = New-Item -ItemType File -Path $filename -Force
            }
          }
          $Selectedpackages | ForEach-Object {
            "winget install -id $($_.Id)" | Out-File -FilePath $filename -Append
          }
          $first = $false
          Clear-Host
          # $result = gum style "Script saved as $file.ps1" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
          # GumOutput -text $result
        }
        1 {  
          $filename = "$file.json"
          if (Test-Path -Path $filename) {
            $replace = gum confirm "File already exists, do you want to replace it?" --affirmative "Yes" --negative "No" && $true || $false
            if ($replace) {
              Remove-Item -Path $filename -Force
              $null = New-Item -ItemType File -Path $filename -Force
            }
          }
          $Selectedpackages | ConvertTo-Json -AsArray | Out-File -FilePath $filename -Append
          $first = $false
          
        }
        Default { return $null }
      }
    }
    $replace = gum confirm "Would you add some entries to the file ?" --affirmative "Yes" --negative "No" && $true || $false
    if (-not $replace) {
      break
    }
  }
  $result = gum style "Script saved as $filename" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
  Clear-Host
  GumOutput -text $result
}

function Start-Winpack {
  Clear-Host
  $result = 0
  while ($result -ne -1) {
    gum style "Welcome to WinPack $script:version" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
    $options = @(
      "Find Packages",
      "List Installed Packages",
      "Install Packages",
      "Update Packages",
      "Uninstall Packages",
      "Build Script",
      "Exit"
    )
    $choice = $options -join "`n" | gum choose 
    Clear-Host
    $index = $options.IndexOf($choice)
    switch ($index) {
      0 { Find-WGPackage }
      1 { get-WGPackage }
      2 { Find-WGPackage -install }
      3 { Get-WGPackage -update }
      4 { Get-WGPackage -uninstall }
      5 { Build-Script }
      6 { $result = -1 }
      Default { $result = -1 }
    }
  }
}
# Find-WGPackage -source "winget"
# Get-WGPackage -source "winget"
#Update-WGPackage -interactive