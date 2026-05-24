$htmlPath = "c:\Users\cmaza\OneDrive\Documentos\ANASTASIA ANTIGRAVITY\press_report\press_report.html"
$capturasPath = "G:\.shortcut-targets-by-id\1mE_Xe8Vb5V3cCyFSbVFmEyxF4WdG7qlQ\CAPTURAS ANASTASIA"

$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8

# Extract JSON
if ($htmlContent -match '(?s)const rawClippingsData = (\[.*?\]);') {
    $jsonStr = $matches[1]
    
    # PowerShell 5.1 sometimes struggles with deeply nested or large JSON if not careful, 
    # but ConvertFrom-Json should work for an array of flat objects.
    $clippings = $jsonStr | ConvertFrom-Json
    
    $existingFilenames = @{}
    foreach ($item in $clippings) {
        $existingFilenames[$item.filename] = $true
    }
    
    $newAdded = 0
    $files = Get-ChildItem -Path $capturasPath -File -Recurse
    
    $newItems = @()
    foreach ($item in $clippings) {
        $newItems += $item
    }

    foreach ($file in $files) {
        if (-not $file.Name.StartsWith('.') -and -not $existingFilenames.ContainsKey($file.Name)) {
            $folder = $file.Directory.Name
            $dateStr = "Desconocida"
            if ($file.Name -match '(\d{2}-\d{2}-\d{4})') {
                $dateStr = $matches[1]
            }
            
            $ext = $file.Extension.ToLower()
            $mediaType = "Prensa Especializada / Portales Web / Redes"
            $noteType = "Mención/Cobertura"
            
            if ($ext -in '.mp4','.mov','.avi') {
                $mediaType = "Televisión / Video Online"
            } elseif ($ext -in '.mp3','.wav') {
                $mediaType = "Radio"
            }
            
            $tone = "Positivo (Difusión)"
            
            # Create a custom object
            $newItem = [PSCustomObject]@{
                filename = $file.Name
                path = $file.FullName
                folder = $folder
                date = $dateStr
                media_type = $mediaType
                note_type = $noteType
                tone = $tone
                extension = $ext
            }
            $newItems += $newItem
            $existingFilenames[$file.Name] = $true
            $newAdded++
        }
    }
    
    Write-Host "Added $newAdded new items."
    
    # Convert back to JSON
    $newJsonStr = $newItems | ConvertTo-Json -Depth 10 -Compress
    # Prettify manually a bit or leave it compressed. The previous was formatted, but compressed is fine.
    
    # Replace in HTML
    $newHtmlContent = $htmlContent -replace '(?s)const rawClippingsData = (\[.*?\]);', ("const rawClippingsData = " + [regex]::Escape($newJsonStr) + ";")
    # Actually -replace interprets $ in replacement string, better to do:
    $splitIndex = $htmlContent.IndexOf($jsonStr)
    $part1 = $htmlContent.Substring(0, $splitIndex)
    $part2 = $htmlContent.Substring($splitIndex + $jsonStr.Length)
    $finalHtml = $part1 + $newJsonStr + $part2

    Set-Content -Path $htmlPath -Value $finalHtml -Encoding UTF8
    Write-Host "Updated HTML successfully."
} else {
    Write-Host "Could not find rawClippingsData in HTML."
}
