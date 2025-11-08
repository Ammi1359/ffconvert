# ConvertBatchVolumeAverage.ps1
# Normalizuje k průměrné hodnotě max_volume (aritmetický průměr), zachovává strukturu, převádí a přesouvá originály do Done.

# Path to FFmpeg (if not in PATH, specify full path e.g. "C:\Tools\ffmpeg.exe")
$ffmpeg = "ffmpeg"

# Relative paths (relative to script)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$inputFolder = Join-Path $scriptDir "IN"
$outputFolder = Join-Path $scriptDir "OUT"
$doneFolder = Join-Path $scriptDir "Done"

# Option: actually run conversion (set $false to only compute/report gains)
$DoConvert = $true

# Helper: ensure folder exists
function Ensure-Folder($path, $label) {
    if (-not (Test-Path $path)) {
        Write-Host "$label folder missing, creating: $path" -ForegroundColor Blue
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

function Log($text, $color = "White") {
    Write-Host $text -ForegroundColor $color
}

# Prompt for output format / crf / preset to match ConvertBatch_v2 behavior
$validFormats = @("mp4", "avi", "mov", "webm")
Write-Host "Available output formats: $($validFormats -join ', ')" -ForegroundColor Blue
$format = Read-Host "Enter desired output format [default: mp4]"
if ([string]::IsNullOrWhiteSpace($format)) { $format = "mp4" }
elseif (-not $validFormats -contains $format.ToLower()) {
    Log "Invalid format. Allowed formats: $($validFormats -join ', ')" "Red"
    exit
}

Write-Host "CRF (quality): lower = better quality, typical range is 18–28" -ForegroundColor Blue
$crf = Read-Host "Enter CRF value [default: 18]"
if ([string]::IsNullOrWhiteSpace($crf)) { $crf = "18" }

$validPresets = @("ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow")
Write-Host "Available presets (speed vs. compression): $($validPresets -join ', ')" -ForegroundColor Blue
$preset = Read-Host "Enter preset [default: slow]"
if ([string]::IsNullOrWhiteSpace($preset)) { $preset = "slow" }
elseif (-not $validPresets -contains $preset.ToLower()) {
    Log "Invalid preset. Allowed presets: $($validPresets -join ', ')" "Red"
    exit
}

# Ensure folders exist
Ensure-Folder $inputFolder "Input"
Ensure-Folder $outputFolder "Output"
Ensure-Folder $doneFolder "Done"

# Collect files recursively
$files = Get-ChildItem -Path $inputFolder -Include *.mkv, *.mp4, *.avi, *.mpg -File -Recurse
if ($files.Count -eq 0) {
    Log "No video files found in '$inputFolder' or its subfolders." "Red"
    exit
}

Log "Files found: $($files.Count)" "Blue"

# Phase 1: measure max_volume for all files
$volumeMap = @{}
$index = 0
$total = $files.Count
foreach ($file in $files) {
    $index++
    Write-Progress -Activity "Analyzing volumes" -Status "Analyzing $($file.Name)" -PercentComplete (($index / $total) * 100)
    $inputPath = $file.FullName
    Log "Analyzing: $($file.Name)" "Blue"

    $volumeInfo = & $ffmpeg -i $inputPath -af volumedetect -f null NUL 2>&1
    $maxVolumeLine = $volumeInfo | Select-String "max_volume:"
    if ($maxVolumeLine) {
        $maxVolumeDb = $maxVolumeLine -replace ".*max_volume: ", "" -replace " dB.*", "" | ForEach-Object { [double]$_ }
    } else {
        Log "Could not determine max_volume for: $($file.Name). Assuming -999 dB." "Red"
        $maxVolumeDb = -999.0
    }
    $volumeMap[$inputPath] = $maxVolumeDb
}

Write-Progress -Activity "Analyzing volumes" -Completed

# Compute arithmetic average (exclude placeholder -999 values)
$validVolumes = $volumeMap.Values | Where-Object { $_ -gt -900 }
if ($validVolumes.Count -eq 0) {
    Log "No valid volume measurements found." "Red"
    exit
}
$averageVolume = ($validVolumes | Measure-Object -Average).Average
Log ("Average peak across files: {0} dB" -f ([math]::Round($averageVolume,2))) "Blue"

# Phase 2: convert each file applying computed gain, preserving folder structure and moving originals to Done
$total = $files.Count
$index = 0
foreach ($file in $files) {
    $index++
    $inputPath = $file.FullName

    # Relative path logic
    $relativePath = $file.DirectoryName.Substring($inputFolder.Length).TrimStart('\')
    $targetFolder = Join-Path $outputFolder $relativePath
    $doneTargetFolder = Join-Path $doneFolder $relativePath
    Ensure-Folder $targetFolder "Output subfolder"
    Ensure-Folder $doneTargetFolder "Done subfolder"

    $outputPath = Join-Path $targetFolder ($file.BaseName + "." + $format)

    Write-Progress -Activity "Video Conversion" -Status "Processing $($file.Name)" -PercentComplete (($index / $total) * 100)

    if (Test-Path $outputPath) {
        Log "Already exists, skipping: $outputPath" "Blue"
        continue
    }

    $currentVolume = $volumeMap[$inputPath]
    if ($currentVolume -eq -999.0) {
        $gainDb = 0
    } else {
        $gainDb = [math]::Round($averageVolume - $currentVolume, 2)
    }

    if ($gainDb -eq 0) {
        Log "Converting without volume change: $($file.Name)" "Blue"
        $audioFilterArgs = @()
    } else {
        Log "Converting with gain ${gainDb} dB: $($file.Name)" "Blue"
        $audioFilterArgs = @("-filter:a", "volume=${gainDb}dB")
    }

    if ($DoConvert) {
        $args = @("-i", $inputPath) + ("-c:v", "libx264", "-preset", $preset, "-crf", $crf, "-c:a", "aac", "-b:a", "192k") + $audioFilterArgs + @($outputPath)
        & $ffmpeg @args

        if (Test-Path $outputPath) {
            Log "Done: $outputPath" "Green"
            # Move original to Done preserving structure
            $donePath = Join-Path $doneTargetFolder $file.Name
            Move-Item -Path $inputPath -Destination $donePath -Force
            Log "Original moved to: $donePath" "Blue"
        } else {
            Log "Error during conversion: $inputPath" "Red"
        }
    } else {
        Log "Dry-run: would run ffmpeg with gain ${gainDb} dB for $($file.Name)" "Blue"
    }
}

Write-Progress -Activity "Video Conversion" -Completed
Log "All conversions finished." "Green"
