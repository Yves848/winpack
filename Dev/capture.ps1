$bufferwidth = ($host.UI.RawUI.BufferSize.Width / 2)
$bufferheight = ($host.UI.RawUI.BufferSize.Height / 2)
$x = ($host.UI.RawUI.BufferSize.Width - $bufferwidth )/2
$y = ($host.UI.RawUI.BufferSize.Height - $bufferheight )/2

$rect = New-Object System.Management.Automation.Host.Rectangle $x, $y, $bufferwidth, $bufferheight

$buffer = $host.ui.RawUI.GetBufferContents($rect)

$buffer | ForEach-Object {
    $line = $_
    $line | ForEach-Object {
        $char = $_
        Write-Host $char.Character -ForegroundColor $char.ForegroundColor -BackgroundColor $char.BackgroundColor -NoNewline
    }
    Write-Host
}