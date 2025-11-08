Written by Nuru - 2025
🧩 What this collection does
This repository contains a PowerShell batch converter and two audio-normalizer helpers that use FFmpeg to process large video libraries on Windows. 
You can convert video formats, preserve folder structure, normalize audio using two strategies (peak-max or arithmetic average), and move originals to a Done folder after successful conversion. 
Scripts are designed to run from the same folder that contains the IN, OUT and Done subfolders.

Components
- ConvertBatch_v2.ps1 — Main converter. Recursively scans IN, preserves relative subfolders in OUT, converts files to chosen format, moves originals to Done, shows progress, and uses color-coded logs. Prompts for output format, CRF and preset.
- ConvertBatchVolumeMax.ps1 — MaxVolume normalizer. Measures each file’s peak using ffmpeg volumedetect, selects the loudest file as reference, computes per-file gain so every file’s peak matches the loudest peak, converts with chosen encoder settings, preserves folder structure, and moves originals to Done.
- ConvertBatchVolumeAverage.ps1 — AverageVolume normalizer. Measures each file’s peak with ffmpeg volumedetect, computes the arithmetic average peak across the set, applies the same gain to all files to reach that average, converts with chosen encoder settings, preserves folder structure, and moves originals to Done.

Requirements
- PowerShell (Windows) — run as Administrator recommended.
- FFmpeg — ffmpeg.exe must be available on your system (in PATH or specify full path in $ffmpeg at the top of each script).
Download FFmpeg:
- Official site: https://ffmpeg.org/download.html
- Recommended Windows build: https://www.gyan.dev/ffmpeg/builds/
After downloading: extract the ZIP and add the path to ffmpeg.exe to your system PATH OR modify the scripts to specify the full path to ffmpeg.exe.

Folder layout and supported formats
- .\IN → place input videos here; scripts scan recursively and preserve relative subfolders.
- .\OUT → converted videos written here, matching IN structure.
- .\Done → originals moved here after successful conversion, matching IN structure.
- Optional .\TEMP → use when you want normalizers to write intermediate normalized copies for review.
- Supported input extensions: .mkv, .mp4, .avi, .mpg (recursive).

How to use — recommended workflows
- Place source videos into .\IN (retain subfolders if desired).
- Choose a normalization strategy:
- Run ConvertBatchVolumeMax.ps1 to match peaks to the loudest file (per-file gains).
- Or run ConvertBatchVolumeAverage.ps1 to align every file to the average peak (uniform gain).
- Workflow options:
- Safe: have the normalizer write normalized copies to .\TEMP, inspect results, then run ConvertBatch_v2.ps1 with IN set to TEMP.
- In-place: let the normalizer overwrite files in .\IN and then run ConvertBatch_v2.ps1.
- Run ConvertBatch_v2.ps1 (or one of the normalizer scripts which also include conversion) and follow prompts for output format, CRF, and preset.
- Verify converted samples in .\OUT and check originals moved to .\Done.

Script options, defaults and behavior
- Output format: mp4, avi, mov, webm (default: mp4).
- CRF: quality for x264 (default: 18; typical range 18–28).
- Preset: encoding speed/compression tradeoff (default: slow; values: ultrafast … veryslow).
- Video codec: libx264 (x264) by default.
- Audio codec: AAC at 192 kbps by default.
- Volume measurement: both normalizers use ffmpeg -af volumedetect and read reported max_volume values.
- MaxVolume strategy: target = maximum of all max_volume values; per-file gain = target − current.
- AverageVolume strategy: target = arithmetic average of valid max_volume values; uniform gain = target − current for each file.
- Preservation of folder structure: all scripts replicate relative input subfolders in OUT and Done.
- Move originals: originals are moved to Done after successful conversion.
- Skipping: if an output file already exists the script skips conversion for that file.
- Dry-run: normalizers include a $DoConvert switch — set to $false to compute/report gains without running ffmpeg.

Practical notes, warnings and tips
- Peak matching (volumedetect) is peak alignment, not perceived loudness. For perceptual loudness consistency across mixed content prefer a LUFS-based workflow (ffmpeg loudnorm).
- Positive gains increase noise floor and can reveal artifacts; large positive gains risk amplifying noise or causing clipping. Review computed gains before mass-processing.
- Test on a small sample or use dry-run before processing a large archive.
- If input files contain multiple audio streams the scripts apply filters to the default audio stream; modify ffmpeg args if you need to target specific streams.
- Back up originals if you must preserve unmodified files.
- If you want LUFS-based normalization, the scripts can be adapted to use loudnorm in two-pass mode — ask for an example.

Examples
- Normalize to the loudest peak then convert to mp4 with CRF 18 and preset slow: run ConvertBatchVolumeMax.ps1 and follow prompts (or set $DoConvert = $true and adjust variables at the top).
- Normalize to an average peak and output to TEMP for review, then run ConvertBatch_v2.ps1 with IN pointing to TEMP.


