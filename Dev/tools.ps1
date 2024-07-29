# using module psCandy
# Import-Module psCandy
# function Get-FieldLength {
#   param(
#     [string]$buffer
#   )
#   $i = 0
#   $buffer.ToCharArray() | ForEach-Object {
#     $l = [Text.Encoding]::UTF8.GetByteCount($_)
#     if ($l -ge 2) {
#       $l = $l - 1
#     }  
#     $i += $l 
#   }
#   return $i
# }

function padRightUTF8
{
  param(
    [string]$text,
    [int]$length
  )
  $bytecount = 0
  $text.ToCharArray() | ForEach-Object {
    $b = [Text.Encoding]::UTF8.Getbytecount($_)
    if ($b -ge 2) {
      $b = $b - 1
    }
    $bytecount += ($b) 
  }

  $totalbytes = [Text.Encoding]::UTF8.GetByteCount("".PadLeft($length," "))
  $diff = $totalbytes - $bytecount
  if ($diff -lt 0) {
    $text.Substring(0, $length)  
  } else {
    [string]::Concat($text, "".PadLeft($diff," "))
  }
  
}

function padLeftUTF8
{
  param(
    [string]$text,
    [int]$length
  )
  $bytecount = 0
  $text.ToCharArray() | ForEach-Object {
    $b = [Text.Encoding]::UTF8.Getbytecount($_)
    if ($b -ge 2) {
      $b = $b - 1
    }
    $bytecount += ($b) 
  }

  $totalbytes = [Text.Encoding]::UTF8.GetByteCount("".PadLeft($length," "))
  $diff = $totalbytes - $bytecount
  [string]::Concat("".PadLeft($diff," "),$text)
}

function Get-ProportionalLength {
  param(
    [int]$MaxLength
  )
  $w = ($Host.UI.RawUI.BufferSize.Width -6)
  return [math]::Floor($w / 100 * $MaxLength)
}

# function TruncateString {
#   param (
#     [string]$InputString,
#     [int]$MaxLength,
#     [Align]$Align = [Align]::Left
#   )
#   $l = Get-FieldLength -buffer $InputString 
#   $w = $Host.UI.RawUI.BufferSize.Width - 6
#   $Maxp = [math]::Floor($w / 100 * $MaxLength)
#   if ($l -le $Maxp) {
#     $pos = 0
#     $offset = 0
#     $TruncatedString = $InputString
#     while ($pos -lt $InputString.Length) {
#       $c = $InputString[$pos]
#       $nbchars = [Text.Encoding]::UTF8.GetByteCount($c)
#       if ($nbchars -gt 1) {
#         $offset += ($nbchars - 2)
#       }
#       $pos++
#     }
#     while ($pos -lt $Maxp - $offset) {
#       switch ($Align) {
#         # TODO: #4 Add Center alignment
#         Left { $TruncatedString += " " }
#         Right { $TruncatedString = " " + $TruncatedString }
#         Default {}
#       }
#       $pos++
#     }
#     return $TruncatedString
#   }

#   $TruncatedString = $InputString.Substring(0, $MaxP - 1) + "…"
#   return $TruncatedString
# }