# using module psCandy
Import-Module C:\Users\yvesg\git\psCandy\Classes\psCandy.psm1
# Import-Module pscandy
Import-Module "$PSScriptRoot\visuals.ps1" -Force
Import-Module "$PSScriptRoot\classes.ps1" -Force
# Import-Module "$PSScriptRoot\tools.ps1" -Force

. "$PSscriptRoot\GumEnv.ps1"

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$module = Get-InstalledModule -Name winpack -ErrorAction SilentlyContinue
if (-not $module) {
  $Script:version = "debug"
}
else {
  $Script:version = $module.Version
}

# TODO: Scoop support
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
    [bool]$update = $false,
    [bool]$uninstall = $false
  )
  $width = ($Host.UI.RawUI.BufferSize.Width - 9)
  $height = ($Host.UI.RawUI.BufferSize.Height - 9)
  [column[]]$cols = @()
  $cols += [column]::new("Name", "Name", 40)
  $cols += [column]::new("Id", "Id", 40)
  $cols += [column]::new("InstalledVersion", "Version", 12, [Align]::Right)
  $cols += [column]::new("Source", "Source", 8, [Align]::Right)
  
  makeExactColWidths -cols $cols -maxwidth $width

  [System.Collections.Generic.List[ListItem]]$choices = makeItems -columns $cols -items $InstalledPackages
  if ($update -eq $true) {
    $title = "List of Packages to Update"
  }
  elseif ($uninstall -eq $true) {
    $title = "List of Packages to Uninstall"
  }
  else {
    $title = "List of Installed Packages"
  }
  $header = makeHeader -columns $cols -width ($width)
  
  [console]::clear()
  Write-Candy -Text "<Coral>$($title)</Coral>" -Border "rounded" -fullscreen -Align Center
  $list = [List]::new($choices)
  $list.SetHeight($height)
  # $list.SetBorder($true)
  $list.setHeader("<Aqua>$header</Aqua>")
  $c = $list.Display()
  [package[]]$packages = @()
  if ($c) {
    $c | ForEach-Object {
      $packages += $_.Value
    }
  }
  Clear-Host
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
    $packages = ShowPackages -InstalledPackages $packages -update $update -uninstall $uninstall
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
  $width = $Host.UI.RawUI.BufferSize.Width - 8
  
  if (-not $query -or $null -eq $query) {
    write-candy "<33>Enter a query to search for a package</33>" -border "rounded" -fullscreen  -align center
    
    $query = gum input --placeholder "Search for a package" 
    $SearchParams.Add("query", $query)
  }

  if ($source) {
    $SearchParams.Add("source", $source)
    $source = build-candy "<I><DodgerBlue>$source</DodgerBlue></I>"
  }
  else {
    $source = build-candy "<I><Red>every sources</Red></I>" 
  }

  if ($query) {
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
    $buffer = [Style]::new("No query specified")
    $buffer.SetBorder($true)
    $buffer.SetColor([Colors]::White(), [Colors]::Red())
    [Console]::Write($buffer.Render())
    Start-Sleep -Seconds 1
    return $null
  }
  if ($packages) {
   
    [column[]]$cols = @()
    $cols += [column]::new("Name", "Name", 40)
    $cols += [column]::new("Id", "Id", 40)
    $cols += [column]::new("Available", "Version", 12, [Align]::Right)
    $cols += [column]::new("Source", "Source", 8, [Align]::Right)

    makeExactColWidths -cols $cols -maxwidth $width

    [package[]]$InstalledPackages = @()
    $packages | ForEach-Object {
      $InstalledPackages += [package]::new($_.Name, $_.Id, $_.AvailableVersions, $_.Source, $_.IsUpdateAvailable, $_.InstalledVersion)
    }
    [System.Collections.Generic.List[ListItem]]$choices = makeItems -columns $cols -items $InstalledPackages
    # $height = $Host.UI.RawUI.BufferSize.Height - 9
    [System.Console]::setcursorposition(0, $Y)
    $header = makeHeader -columns $cols -width $width
    $Spinner.Stop()
    Clear-Host
    Write-Candy -Text "<CornflowerBlue>Choose Packages to Install</CornflowerBlue>" -Border "rounded" -Width $width -Align Center
    $list = [List]::new($choices)
    $list.setHeader("<Aqua>$($header)</Aqua>")
    $list.headerColor = $headercolor
    $c = $list.Display()
    [package[]]$packages = @()
    if ($c) {
      $c | ForEach-Object {
        $packages += $_.Value
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
  param (
    [switch]$preview = $false
  )
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
          $header = @(
            "#",
            "# Path: $filename",
            "# Generated by WinPack $script:version",
            "# Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")",
            "#"
          )
          if ($true -eq $first) {
            if (Test-Path -Path $filename) {
              # TODO: Optimize this part
              $replace = gum confirm "File already exists, do you want to replace it?" --affirmative "Yes" --negative "No" && $true || $false
              if ($replace) {
                Remove-Item -Path $filename -Force
                $null = New-Item -ItemType File -Path $filename -Force
                $header -join "`n" | Out-File -FilePath $filename -Append
              }
            }
            else {
              $null = New-Item -ItemType File -Path $filename -Force
              $header -join "`n" | Out-File -FilePath $filename -Append
            }
          }
          $Selectedpackages | ForEach-Object {
            "winget install --id $($_.Id) # $($_.Name)" | Out-File -FilePath $filename -Append
            $id = $_.Id
            $packages = $packages | Where-Object { $_.Id -ne $Id }
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
    if ($filename) {
      $replace = gum confirm "Would you add some entries to the file ?" --affirmative "Yes" --negative "No" && $true || $false
      if (-not $replace) {
        break
      }
    }
    else {
      break
    }
  }
  if ($filename) {
    $result = gum style "Script saved as $filename" --foreground $($Theme["brightYellow"]) --bold --border rounded --width ($Host.UI.RawUI.BufferSize.Width - 2) --align center
    Clear-Host
    GumOutput -text $result
    if ($preview) {
      Get-Content -Path $filename | gum pager --height ($Host.UI.RawUI.BufferSize.Height / 2) --width ($Host.UI.RawUI.BufferSize.Width % 2) --border "rounded"
    }
  }
}

function Start-Winpack {
  Clear-Host
  $result = 0
  $width = $Host.UI.RawUI.BufferSize.Width - 2
  while ($result -ne -1) {
    [Console]::setcursorposition(0, 0)
    Write-Candy -Text "<Yellow>Welcome to Winpack</Yellow> <CornflowerBlue><Italic>$($script:version)</Italic></CornflowerBlue>" -Border "rounded" -fullscreen -Align Center
    
    $items = [System.Collections.Generic.List[ListItem]]::new()
    $items.Add([ListItem]::new("Find Packages", 0, "🔎"))
    $items.Add([ListItem]::new("List Installed Packages", 1, "📃"))
    $items.Add([ListItem]::new("Install Packages", 2, "📦"))
    $items.Add([ListItem]::new("Update Packages", 3, "🌀"))
    $items.Add([ListItem]::new("<Red>Uninstall Packages</Red>", 4, "🗑️"))
    $items.Add([ListItem]::new("Build Script", 5, "📜"))
    $items.Add([ListItem]::new("Exit", 100, "❌"))
    

    $list = [List]::new($items)  
    $list.SetLimit($true)
    # $list.SetWidth($width)
    $index = $list.Display()
    switch ($index.value) {
      0 { $null = Find-WGPackage -source "winget" }
      1 { Get-WGPackage -source "winget" }
      2 { $null = Find-WGPackage -install }
      3 { Get-WGPackage -update }
      4 { Get-WGPackage -uninstall }
      5 { Build-Script }
      100 { $result = -1 }
      Default { $result = -1 }
    }
  }
}


Start-Winpack