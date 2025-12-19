$webroot = "C:\Users\gotti\Documents\datalogger\build\web"
$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

try {
    $listener.Start()
    Write-Host "Server running at http://localhost:$port" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $path = $request.Url.LocalPath
            if ($path -eq "/" -or $path -eq "") { $path = "/index.html" }
            $filePath = $webroot + $path.Replace("/", "\")
            
            if (Test-Path $filePath -PathType Leaf) {
                $content = [IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $content.Length
                $response.StatusCode = 200
                
                if ($filePath.EndsWith(".html")) { $response.ContentType = "text/html; charset=utf-8" }
                elseif ($filePath.EndsWith(".js")) { $response.ContentType = "application/javascript; charset=utf-8" }
                elseif ($filePath.EndsWith(".json")) { $response.ContentType = "application/json; charset=utf-8" }
                elseif ($filePath.EndsWith(".css")) { $response.ContentType = "text/css; charset=utf-8" }
                elseif ($filePath.EndsWith(".png")) { $response.ContentType = "image/png" }
                elseif ($filePath.EndsWith(".svg")) { $response.ContentType = "image/svg+xml" }
                elseif ($filePath.EndsWith(".wasm")) { $response.ContentType = "application/wasm" }
                else { $response.ContentType = "application/octet-stream" }
                
                $response.OutputStream.Write($content, 0, $content.Length)
                $response.OutputStream.Close()
                Write-Host "$($request.HttpMethod) $($request.Url.LocalPath) -> 200" -ForegroundColor Cyan
            } else {
                $response.StatusCode = 404
                $response.ContentType = "text/plain"
                $bytes = [Text.Encoding]::UTF8.GetBytes("404 Not Found: $filePath")
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.OutputStream.Close()
                Write-Host "$($request.HttpMethod) $($request.Url.LocalPath) -> 404" -ForegroundColor Red
            }
        } catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Server error: $_" -ForegroundColor Red
} finally {
    $listener.Stop()
    $listener.Close()
}
