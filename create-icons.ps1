Add-Type -AssemblyName System.Drawing

# Create 512x512 icon
$bitmap512 = New-Object System.Drawing.Bitmap(512, 512)
$graphics512 = [System.Drawing.Graphics]::FromImage($bitmap512)
$graphics512.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Background gradient
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Point]::new(0, 0),
    [System.Drawing.Point]::new(512, 512),
    [System.Drawing.Color]::FromArgb(102, 126, 234),
    [System.Drawing.Color]::FromArgb(118, 75, 162)
)
$graphics512.FillRectangle($brush, 0, 0, 512, 512)

# White rounded rectangle (form)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
$graphics512.FillRectangle($whiteBrush, 100, 150, 312, 250)

# Purple circle (logo element)
$purpleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(102, 126, 234))
$graphics512.FillEllipse($purpleBrush, 226, 180, 60, 60)

# Horizontal bars
$graphics512.FillRectangle($purpleBrush, 180, 270, 152, 20)
$graphics512.FillRectangle($purpleBrush, 180, 310, 152, 20)

$bitmap512.Save("$PSScriptRoot\icon-512.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Create 192x192 icon
$bitmap192 = New-Object System.Drawing.Bitmap(192, 192)
$graphics192 = [System.Drawing.Graphics]::FromImage($bitmap192)
$graphics192.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics192.DrawImage($bitmap512, 0, 0, 192, 192)
$bitmap192.Save("$PSScriptRoot\icon-192.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Cleanup
$graphics512.Dispose()
$bitmap512.Dispose()
$graphics192.Dispose()
$bitmap192.Dispose()

Write-Host "Icons created successfully!" -ForegroundColor Green
Write-Host "  - icon-512.png" -ForegroundColor Cyan
Write-Host "  - icon-192.png" -ForegroundColor Cyan
