# GUM dfault environment variables
$env:GUM_FILTER_INDICATOR = "▶ "
$env:GUM_FILTER_INDICATOR_FOREGROUND = $Theme["green"]
$env:BORDER_FOREGROUND = $($Theme["purple"])
$env:GUM_CHOOSE_SELECTED_BACKGROUND = $Theme["green"]
$env:GUM_CHOOSE_SELECTED_FOREGROUND = $Theme["white"]
$env:GUM_FILTER_CURSOR_TEXT_UNDERLINE = 1 #cursor-text.underline
$env:GUM_CONFIRM_PROMPT_WIDTH = $Host.UI.RawUI.WindowSize.Width -2
$env:GUM_CONFIRM_PROMPT_ALIGN = "center"
$env:GUM_CONFIRM_PROMPT_BORDER = "rounded"
$env:GUM_CONFIRM_PROMPT_BORDER_FOREGROUND = $Theme["purple"]