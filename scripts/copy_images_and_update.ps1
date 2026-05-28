$htmlPath = "c:\Users\cmaza\OneDrive\Documentos\ANASTASIA ANTIGRAVITY\press_report\press_report.html"
$destDir = "c:\Users\cmaza\OneDrive\Documentos\ANASTASIA ANTIGRAVITY\press_report\capturas"

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8

if ($htmlContent -match '(?s)const rawClippingsData = (\[.*?\]);') {
    $jsonStr = $matches[1]
    $clippings = $jsonStr | ConvertFrom-Json
    
    $copiedCount = 0
    
    foreach ($item in $clippings) {
        $ext = $item.extension.ToLower()
        if ($ext -in '.png', '.jpg', '.jpeg') {
            # Needs copying
            $sourcePath = $item.path
            
            # Check if sourcePath is still pointing to G: drive
            if ($sourcePath -match '^G:\\') {
                $destPath = Join-Path -Path $destDir -ChildPath $item.filename
                
                if (Test-Path -Path $sourcePath) {
                    if (-not (Test-Path -Path $destPath)) {
                        Copy-Item -Path $sourcePath -Destination $destPath
                        $copiedCount++
                    }
                    # Update path in JSON to relative path for HTML
                    $item.path = "./capturas/" + $item.filename
                }
            }
        }
    }
    
    Write-Host "Copied $copiedCount images."
    
    $newJsonStr = $clippings | ConvertTo-Json -Depth 10 -Compress
    
    $splitIndex = $htmlContent.IndexOf($jsonStr)
    $part1 = $htmlContent.Substring(0, $splitIndex)
    $part2 = $htmlContent.Substring($splitIndex + $jsonStr.Length)
    $finalHtml = $part1 + $newJsonStr + $part2

    Set-Content -Path $htmlPath -Value $finalHtml -Encoding UTF8
    Write-Host "Updated HTML successfully."
} else {
    Write-Host "Could not find rawClippingsData in HTML."
}
