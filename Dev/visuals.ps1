using module ..\..\psCandy\Classes\psCandy.psm1

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
      $icon = "!"
    }
    $columns | ForEach-Object {
      $fieldname = $_.FieldName
      $width = [int32]$_.Width
      # $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
      $buffer = padRightUTF8 -text $([string]$item."$fieldname") -length $width
      $temp = [string]::Concat($temp, [string]$buffer, " ")
    }
    [ListItem]$li = [ListItem]::new($temp, $item,$icon,[Colors]::Green()) 
    $li.IconColor = [Color]::New([Colors]::Orange())
    $result.Add($li)
    $index ++
  }
  return $result
}

function makeHeader {
  param(
    [column[]]$columns
  )
  $index = 0
  [string]$temp = ""
   
  $columns | ForEach-Object {
    $fieldname = $_.FieldName
    $width = [int32]$_.Width
    # $buffer = TruncateString -InputString $([string]$item."$fieldname") -MaxLength $width -Align $_.Align
    $buffer = padRightUTF8 -text $fieldname -length $width
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