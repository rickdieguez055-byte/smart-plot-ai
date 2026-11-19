$token = Get-Content "C:\Users\Mueed\.gemini\antigravity\brain\codemagic_token.txt"
$ghToken = Get-Content "C:\Users\Mueed\.gemini\antigravity\brain\github_token.txt"
$buildId = "6aff362b7309ec9b5a48ac94"
$headers = @{ "x-auth-token" = $token }

Write-Host "Monitoring Codemagic Build: $buildId on Mac mini M2..."

function Restore-RepoPrivate {
    try {
        $ghHeaders = @{ "Authorization" = "token $ghToken"; "User-Agent" = "SmartPlotAI"; "Content-Type" = "application/json" }
        $body = @{ private = $true } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.github.com/repos/rickdieguez055-byte/smart-plot-ai" -Method Patch -Headers $ghHeaders -Body $body | Out-Null
        Write-Host "GitHub repository successfully restored to Private." -ForegroundColor Green
    } catch {
        Write-Host "Warning restoring repo to private: $_"
    }
}

$isDone = $false
while (-not $isDone) {
    Start-Sleep -Seconds 15
    try {
        $res = Invoke-RestMethod -Uri "https://api.codemagic.io/builds/$buildId" -Headers $headers
        $status = $res.build.status
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] Build Status: $status"

        if ($status -eq "building") {
            $currentAction = $res.build.buildActions | Where-Object { $_.status -eq "running" } | Select-Object -First 1
            if ($currentAction) {
                Write-Host "  -> Running step: $($currentAction.name)"
            }
        } elseif ($status -eq "finished") {
            $isDone = $true
            Write-Host "Build finished successfully!" -ForegroundColor Green

            # Immediately secure repository
            Restore-RepoPrivate

            $artifacts = $res.build.artefacts
            $ipa = $artifacts | Where-Object { $_.name -like "*.ipa" } | Select-Object -First 1
            if ($ipa) {
                Write-Host "Found IPA Artifact: $($ipa.name) ($($ipa.size) bytes)"
                $downloadUrl = $ipa.url
                
                $desktopDest = "C:\Users\Mueed\Desktop\$($ipa.name)"
                $projectDest = "C:\Users\Mueed\Desktop\smart plot_ai\build\$($ipa.name)"
                
                if (-not (Test-Path "C:\Users\Mueed\Desktop\smart plot_ai\build")) {
                    New-Item -ItemType Directory -Path "C:\Users\Mueed\Desktop\smart plot_ai\build" -Force | Out-Null
                }

                Write-Host "Downloading to Desktop: $desktopDest..."
                Invoke-WebRequest -Uri $downloadUrl -Headers $headers -OutFile $desktopDest
                Copy-Item -Path $desktopDest -Destination $projectDest -Force

                Write-Host "IPA File successfully downloaded to:" -ForegroundColor Green
                Write-Host "1. $desktopDest" -ForegroundColor Green
                Write-Host "2. $projectDest" -ForegroundColor Green
            } else {
                Write-Host "Warning: No .ipa artifact found in finished build." -ForegroundColor Yellow
            }
        } elseif ($status -in @("failed", "canceled", "timeout")) {
            $isDone = $true
            Restore-RepoPrivate
            Write-Host "Build ended with status: $status" -ForegroundColor Red
            Write-Host "Message: $($res.build.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Polling error: $_"
    }
}
