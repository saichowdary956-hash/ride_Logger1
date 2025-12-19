# Simple HTTP Server for DataLogger PWA
$port = 8080
$path = $PSScriptRoot

Write-Host "Starting DataLogger Server..." -ForegroundColor Green
Write-Host "Server running at: http://localhost:$port/app.html" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Open browser
Start-Process "http://localhost:$port/app.html"

# Start simple HTTP server
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "Server started successfully!" -ForegroundColor Green
Write-Host "After the page loads once, you can:" -ForegroundColor Yellow
Write-Host "  1. Close this server (Ctrl+C)" -ForegroundColor White
Write-Host "  2. Use the app OFFLINE - it's cached!" -ForegroundColor White
Write-Host ""

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $requestedFile = $request.Url.LocalPath.TrimStart('/')
        if ($requestedFile -eq '') { $requestedFile = 'app.html' }
        
        $filePath = Join-Path $path $requestedFile
        
        if (Test-Path $filePath) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            
            # Set content type
            $ext = [System.IO.Path]::GetExtension($filePath)
            $contentType = switch ($ext) {
                '.html' { 'text/html' }
                '.js'   { 'application/javascript' }
                '.json' { 'application/json' }
                '.png'  { 'image/png' }
                '.svg'  { 'image/svg+xml' }
                default { 'application/octet-stream' }
            }
            
            $response.ContentType = $contentType
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
            
            Write-Host "✓ Served: $requestedFile" -ForegroundColor Gray
        }
        else {
            $response.StatusCode = 404
            Write-Host "✗ Not found: $requestedFile" -ForegroundColor Red
        }
        
        $response.Close()
    }
}
finally {
    $listener.Stop()
    Write-Host "Server stopped." -ForegroundColor Yellow
}
