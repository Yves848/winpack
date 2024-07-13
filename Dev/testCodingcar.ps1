$string1 = "小程序开发者工具"
$string2 = "Coucou"

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
  [string]::Concat($text, "".PadLeft($diff,"."))
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
  [string]::Concat("".PadLeft($diff,"."),$text)
}


[console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::WriteLine("$string1 $($string1.Length)")
[Console]::WriteLine("$string2 $($string2.Length)")

padRightUTF8 -text $string1 -length 32
padRightUTF8 -text $string2 -length 32
padLeftUTF8 -text $string1 -length 32
padLeftUTF8 -text $string2 -length 32