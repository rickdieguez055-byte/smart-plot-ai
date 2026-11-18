# ==============================================================================
# SmartPlot AI — Codemagic iOS Build & IPA Retrieval Automation
# Project #22 • City University of Science and Information Technology (CUSIT)
# ==============================================================================

param (
    [string]$GitHubRepoUrl = "",
    [string]$CodemagicToken = "",
    [string]$CodemagicAppId = "",
    [string]$Workflow = "ios-unsigned-ipa"
)

$ErrorActionPreference = "Stop"
$ProjectDir = "C:\Users\Mueed\Desktop\smart plot_ai"
Set-Location $ProjectDir

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  SMARTPLOT AI - iOS IPA BUILD VIA CODEMAGIC" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Git Status
Write-Host "[1/4] Checking Git repository status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Uncommitted changes found. Staging and committing..." -ForegroundColor DarkYellow
    git add .
    git commit -m "chore: save changes before Codemagic iOS build"
} else {
    Write-Host "Working tree is clean." -ForegroundColor Green
}

# 2. Push to GitHub
Write-Host ""
Write-Host "[2/4] Verifying GitHub Remote..." -ForegroundColor Yellow
$remotes = git remote -v
if (-not $remotes) {
    if (-not $GitHubRepoUrl) {
        $GitHubRepoUrl = Read-Host "Enter your GitHub repository URL (e.g. https://github.com/username/smartplot-ai.git)"
    }
    if ($GitHubRepoUrl) {
        Write-Host "Adding remote origin: $GitHubRepoUrl" -ForegroundColor Cyan
        git remote add origin $GitHubRepoUrl
    } else {
        Write-Host "Warning: No GitHub remote provided. Push cannot proceed automatically." -ForegroundColor Red
    }
}

if (git remote) {
    Write-Host "Pushing master branch to remote origin..." -ForegroundColor Cyan
    try {
        git push -u origin master
        Write-Host "Successfully pushed latest commits to GitHub." -ForegroundColor Green
    } catch {
        Write-Host "Push failed. Please ensure you have write permissions or are signed into Git." -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
    }
}

# 3. Trigger Codemagic Build (if token provided)
Write-Host ""
Write-Host "[3/4] Triggering Codemagic Cloud Build..." -ForegroundColor Yellow
if ($CodemagicToken -and $CodemagicAppId) {
    $headers = @{
        "x-auth-token" = $CodemagicToken
        "Content-Type" = "application/json"
    }
    $body = @{
        "appId" = $CodemagicAppId
        "workflowId" = $Workflow
        "branch" = "master"
    } | ConvertTo-Json

    Write-Host "Calling Codemagic API to start workflow '$Workflow'..." -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri "https://api.codemagic.io/builds" -Method Post -Headers $headers -Body $body
        $buildId = $response.buildId
        Write-Host "Build successfully started! Build ID: $buildId" -ForegroundColor Green
        Write-Host "Build Dashboard: https://codemagic.io/app/$CodemagicAppId/build/$buildId" -ForegroundColor Cyan

        # Poll Build Status
        Write-Host ""
        Write-Host "[4/4] Monitoring build status in cloud (takes ~5-7 minutes)..." -ForegroundColor Yellow
        $isFinished = $false
        while (-not $isFinished) {
            Start-Sleep -Seconds 20
            $statusRes = Invoke-RestMethod -Uri "https://api.codemagic.io/builds/$buildId" -Method Get -Headers $headers
            $status = $statusRes.build.status
            Write-Host "Current Status: $status ($(Get-Date -Format 'HH:mm:ss'))" -ForegroundColor DarkGray

            if ($status -eq "finished") {
                $isFinished = $true
                Write-Host "Build finished successfully!" -ForegroundColor Green
                
                # Retrieve Artifacts
                $artifacts = $statusRes.build.artefacts
                $ipaArtifact = $artifacts | Where-Object { $_.name -like "*.ipa" } | Select-Object -First 1
                if ($ipaArtifact) {
                    $downloadUrl = $ipaArtifact.url
                    $outDir = Join-Path $ProjectDir "build"
                    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
                    $destPath = Join-Path $outDir $ipaArtifact.name

                    Write-Host "Downloading IPA artifact to: $destPath" -ForegroundColor Cyan
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath
                    Write-Host "IPA downloaded successfully: $destPath" -ForegroundColor Green
                    Write-Host "You can now drag this IPA directly into Sideloadly to install on your iPhone!" -ForegroundColor Green
                }
            } elseif ($status -in @("failed", "canceled", "timeout")) {
                $isFinished = $true
                Write-Host "Build ended with status: $status" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "API invocation error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "No Codemagic API token supplied." -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "To complete the build in the Codemagic Web UI:" -ForegroundColor Cyan
    Write-Host "1. Open https://codemagic.io and login with GitHub."
    Write-Host "2. Select your repository."
    Write-Host "3. Click 'Start new build' -> select '$Workflow' -> click 'Start build'."
    Write-Host "4. When complete, download the IPA from the Artifacts tab!"
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
