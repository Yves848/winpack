using module psCandy

function makeItems {
  param(
    [column[]]$columns,
    [package[]]$items
  )
  $icon = $null
  $index = 0
  [System.Collections.Generic.List[ListItem]]$result = [System.Collections.Generic.List[ListItem]]::new()
  while ($index -lt $items.Count) {
    $icon = " "
    $item = $items[$index]
    [string]$temp = ""
    if ($item.IsUpdateAvailable) {
      $icon = "↺"
    }
    $columns | ForEach-Object {
      $fieldname = $_.FieldName
      $width = [int32]$_.ExactWidth
      # $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
      # $buffer = padRightUTF8 -text $([string]$item."$fieldname") -length $width
      $buffer = [candyString]::PadString($([string]$item."$fieldname"), $width, " ", $_.Align)
      $temp = [string]::Concat($temp, [string]$buffer, " ")
    }
    [ListItem]$li = [ListItem]::new($temp, $item, $icon, [Colors]::Green()) 
    $li.IconColor = [Color]::New([Colors]::Orange())
    $result.Add($li)
    $index ++
  }
  return $result
}

function makeExactColWidths {
  param(
    [column[]]$cols,
    [int]$maxwidth
  )
  $totalWidth = ($cols | Measure-Object -Property Width -Sum).Sum

  # Calculate the percentage width for each column relative to $maxwidth and floor the values
  $calculatedWidths = @{}
  $cols | ForEach-Object {
    $colWidthPercentage = $_.Width / $totalWidth
    $calculatedWidth = [math]::Floor($maxwidth * $colWidthPercentage)
    $calculatedWidths[$_.FieldName] = $calculatedWidth
  }

  # Calculate the sum of calculated widths
  $sumCalculatedWidths = ($calculatedWidths.Values | Measure-Object -Sum).Sum

  # Distribute the remaining width to columns
  $remainingWidth = $maxwidth - $sumCalculatedWidths

  # Sort columns by their initial widths to fairly distribute the remaining width
  $sortedCols = $calculatedWidths.Keys | Sort-Object { $calculatedWidths[$_] }
  for ($i = 0; $i -lt $remainingWidth; $i++) {
    $colName = $sortedCols[$i % $sortedCols.Count]
    $calculatedWidths[$colName] += 1
  }

  # Output the final widths
  foreach ($col in $cols) {
    $col.ExactWidth = $calculatedWidths[$col.FieldName]
    # Write-Output "Column: $($col.FieldName), Exact Width: $($col.ExactWidth)"
  }
}

function makeHeader {
  param(
    [column[]]$columns,
    [int]$width
  )
  [string]$temp = ""
   
  $columns | ForEach-Object {
    $fieldname = $_.FieldName
    $w = [int32]$_.ExactWidth 
    $buffer = [candyString]::PadString($fieldname, $w, " ", $_.Align)
    $temp = [string]::Concat($temp, [string]$buffer, " ")
  }
  return $temp
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