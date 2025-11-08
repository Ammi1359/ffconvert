# Path to FFmpeg (if not in PATH, specify full path e.g. "C:\Tools\ffmpeg.exe")
$ffmpeg = "ffmpeg"

# Relative paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$inputFolder = Join-Path $scriptDir "IN"
$outputFolder = Join-Path $scriptDir "OUT"
$doneFolder = Join-Path $scriptDir "Done"

# Helper: ensure folder exists
function Ensure-Folder($path, $label) {
    if (-not (Test-Path $path)) {
        Write-Host "$label folder missing, creating: $path" -ForegroundColor Blue
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

# Helper: colored message
function Log($text, $color = "White") {
    Write-Host $text -ForegroundColor $color
}

# Output format selection
$validFormats = @("mp4", "avi", "mov", "webm")
Write-Host "Available output formats: $($validFormats -join ', ')" -ForegroundColor Blue
$format = Read-Host "Enter desired output format [default: mp4]"
if ([string]::IsNullOrWhiteSpace($format)) { $format = "mp4" }
elseif (-not $validFormats -contains $format.ToLower()) {
    Log "Invalid format. Allowed formats: $($validFormats -join ', ')" "Red"
    exit
}

# CRF selection
Write-Host "CRF (quality): lower = better quality, typical range is 18-28" -ForegroundColor Blue
$crf = Read-Host "Enter CRF value [default: 18]"
if ([string]::IsNullOrWhiteSpace($crf)) { $crf = "18" }

# Preset selection
$validPresets = @("ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow")
Write-Host "Available presets (speed vs. compression): $($validPresets -join ', ')" -ForegroundColor Blue
$preset = Read-Host "Enter preset [default: slow]"
if ([string]::IsNullOrWhiteSpace($preset)) { $preset = "slow" }
elseif (-not $validPresets -contains $preset.ToLower()) {
    Log "Invalid preset. Allowed presets: $($validPresets -join ', ')" "Red"
    exit
}

# Ensure folders
Ensure-Folder $inputFolder "Input"
Ensure-Folder $outputFolder "Output"
Ensure-Folder $doneFolder "Done"

# Get all video files recursively
$files = Get-ChildItem -Path $inputFolder -Include *.mkv, *.avi, *.mpg, *.mp4 -File -Recurse
if ($files.Count -eq 0) {
    Log "No video files found in '$inputFolder' or its subfolders." "Red"
    exit
}

Log "Files found: $($files.Count)" "Blue"
$total = $files.Count
$index = 0

foreach ($file in $files) {
    $index++
    $inputPath = $file.FullName

    # Get relative path from input folder
    $relativePath = $file.DirectoryName.Substring($inputFolder.Length).TrimStart('\')
    $targetFolder = Join-Path $outputFolder $relativePath
    $doneTargetFolder = Join-Path $doneFolder $relativePath

    # Ensure target subfolders exist
    Ensure-Folder $targetFolder "Output subfolder"
    Ensure-Folder $doneTargetFolder "Done subfolder"

    # Build output path with preserved structure
    $outputPath = Join-Path $targetFolder ($file.BaseName + "." + $format)

    Write-Progress -Activity "Video Conversion" -Status "Processing $($file.Name)" -PercentComplete (($index / $total) * 100)

    if (Test-Path $outputPath) {
        Log "Already exists, skipping: $outputPath" "Blue"
        continue
    }

    Log "Converting: $inputPath -> $outputPath" "Blue"
    #& $ffmpeg -i $inputPath -c:v libx264 -preset $preset -crf $crf -c:a aac -b:a 192k $outputPath
	& $ffmpeg -hide_banner -nostdin -y -i $inputPath -c:v libx264 -preset $preset -crf $crf -c:a aac -b:a 192k -stats -loglevel error $outputPath

    if (Test-Path $outputPath) {
        Log "Done: $outputPath" "Green"

        # Move original file to Done folder
        $donePath = Join-Path $doneTargetFolder $file.Name
        Move-Item -Path $inputPath -Destination $donePath -Force
        Log "Original moved to: $donePath" "Blue"
    } else {
        Log "Error during conversion: $inputPath" "Red"
    }
}

Write-Progress -Activity "Video Conversion" -Completed
Log "All conversions finished." "Green"