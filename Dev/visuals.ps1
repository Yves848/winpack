using module psCandy

function makeLines {
  param(
    [column[]]$columns,
    [package[]]$items
  )

  $index = 0
  [string]$line = ""
  while ($index -lt $items.Count) {
    $item = $items[$index]
    [string]$temp = ""
    if ($item.IsUpdateAvailable) {
      $temp = [string]::Concat($temp, "↺ ")
    }
    else {
      $temp = [string]::Concat($temp, "  ")
    }
    $columns | ForEach-Object {
      $fieldname = $_.FieldName
      $width = [int32]$_.Width
      $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
      $temp = [string]::Concat($temp, [string]$buffer, " ")
    }

    $line = [string]::Concat($line, $temp)
    
    if ($index -lt $items.Count - 1) {
      $line = [string]::Concat($line, "`n")
    }
    $index ++
  }
  return $line
}

function makeItems {
  param(
    [column[]]$columns,
    [package[]]$items
  )

  $index = 0
  $result = [System.Collections.Generic.List[ListItem]]::new()
  while ($index -lt $items.Count) {
    $item = $items[$index]
    [string]$temp = ""
    if ($item.IsUpdateAvailable) {
      $temp = [string]::Concat($temp, "↺ ")
    }
    else {
      $temp = [string]::Concat($temp, "  ")
    }
    $columns | ForEach-Object {
      $fieldname = $_.FieldName
      $width = [int32]$_.Width
      $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
      $temp = [string]::Concat($temp, [string]$buffer, " ")
    }

    $result.Add([ListItem]::new($temp,$item))
    $index ++
  }
  return $result
}

function makeHeader {
  param(
    [column[]]$columns
  )
  $header = "   "
  $index = 0
  # TODO: #1 fix the white line if the terminal is too small
  $columns | ForEach-Object {
    $w = Get-ProportionalLength -MaxLength $_.Width
    $filler = " "
    if ($index -eq $columns.Count - 1) {
      $filler = ""
    }
    $Label = $_.Label
    switch ($_.Align) {
      # TODO: #4 Add Center alignment
      Left { $colName = $Label.PadRight($w, " ") }
      Right { $colName = $Label.PadLeft($w, " ") }
      Default {}
    }
    $header = [string]::Concat($header, $colName, $filler)
    $index ++
  }
  $result = [Style]::new($([string]::Concat("    ", $header)))
  $result.SetColor([Colors]::Yellow())
  return $result.render()
}

function makeTitle {
  param(
    [string]$title,
    [int]$width
  )
  $w = ($width / 2) + ($title.Length / 2)
  $title = $title.PadLeft($w, " ")
  $title = $title.PadRight($width, " ")
  $result = [Style]::new($title)
  $result.SetColor([Colors]::Purple(), [Colors]::White())
  $result.setAlign([Align]::Center)
  return $result.render()
}

function GumOutput {
  param(
    [string[]]$Text
  )
  $Text | ForEach-Object {
    [System.Console]::WriteLine($_)
  }
}