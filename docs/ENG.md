Written by Nuru — 2025
Overview
- This collection provides a PowerShell batch converter and two audio-normalizer helpers that use FFmpeg to process large video libraries on Windows. You can convert video formats, preserve folder structure, normalize audio using two strategies (peak-max or arithmetic average), and move originals to a Done folder after successful conversion. Scripts are designed to run from the same folder that contains the IN, OUT and Done subfolders.

REPO:
https://github.com/Ammi1359/ffconvert

Components
- ConvertBatch_v2.ps1 — Main converter
Recursively scans IN, preserves relative subfolders in OUT, converts files to chosen format, moves originals to Done on success, shows progress, and uses color-coded logs. Prompts for output format, CRF and preset.
- ConvertBatchVolumeMax.ps1 — MaxVolume normalizer
Measures each file’s peak using ffmpeg -af volumedetect, selects the loudest file as reference, computes per-file gain so every file’s peak matches that loudest peak, converts with chosen encoder settings, preserves folder structure, and moves originals to Done.
- ConvertBatchVolumeAverage.ps1 — AverageVolume normalizer
Measures each file’s peak with ffmpeg -af volumedetect, computes the arithmetic average peak across the set, applies the same gain to all files to reach that average, converts with chosen encoder settings, preserves folder structure, and moves originals to Done.

Requirements
- PowerShell on Windows (running as Administrator is recommended).
- FFmpeg (ffmpeg.exe) available in PATH or set the full path in the $ffmpeg variable at the top of each script.
FFmpeg builds: https://ffmpeg.org/download.html

Folder layout and supported formats
- .\IN → place input videos here; scripts scan recursively and preserve relative subfolders.
- .\OUT → converted videos written here, matching IN structure.
- .\Done → originals moved here after successful conversion, matching IN structure.
- Optional .\TEMP → use when you want normalizers to write intermediate normalized copies for review.
Supported input extensions (recursive): .mkv, .mp4, .avi, .mpg.

Options and prompts (what you’ll be asked)
- Output format: mp4, avi, mov, webm (default: mp4).
- CRF: quality for x264 (default: 18; typical range 18–28). Lower = better quality.
- Preset: encoding speed/compression tradeoff (default: slow; valid: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow).
- Normalizer scripts include a $DoConvert switch — set to $false for dry-run (compute/report gains only).
Default encoding in scripts: video libx264, audio aac at 192k.

How each normalizer works
- MaxVolume
- Scans all files with ffmpeg -af volumedetect and reads max_volume for each file.
- Chooses the highest max_volume as the target peak.
- Computes per-file gain = target − current (dB) and applies -filter:a "volume=XdB" during conversion.
- Converts files to chosen format and moves originals to Done.
- AverageVolume
- Scans all files and reads max_volume values.
- Computes the arithmetic average of valid measurements as the target.
- Computes identical gain for each file = target − current (dB) and applies -filter:a "volume=XdB" during conversion.
- Converts files to chosen format and moves originals to Done.
Note: Both normalizers are peak-based (use max_volume), not LUFS-based loudness normalization.

Recommended workflows
- Put source videos into .\IN (keep subfolders if needed).
- Choose normalization strategy:
- ConvertBatchVolumeMax.ps1 — match every file’s peak to the loudest file (per-file gains).
- ConvertBatchVolumeAverage.ps1 — align every file to the average peak (uniform gain).
- Workflow options:
- Safe: normalizer writes normalized copies to .\TEMP → inspect results → run ConvertBatch_v2.ps1 with IN = TEMP.
- In-place: normalizer overwrites .\IN → run ConvertBatch_v2.ps1.
- Run the converter and follow prompts for format/CRF/preset.
- Check converted samples in .\OUT and confirm originals were moved to .\Done.

Behavior summary
- Scripts create missing folders (IN, OUT, Done) as needed.
- Relative input subfolder tree is preserved in OUT and Done.
- If a target output file already exists, the script skips conversion for that file.
- After successful conversion the original file is moved to the corresponding path under Done.
- Progress is shown with a progress bar and color-coded messages (errors in red, info in blue, success in green).
- Normalizers can run in dry-run mode to print computed gains without executing ffmpeg.

Practical notes, warnings and tips
- Peak alignment (volumedetect) is not the same as perceived loudness (LUFS). For perceptual loudness consistency across varied content prefer a LUFS-based workflow (ffmpeg loudnorm two-pass).
- Applying positive gain increases noise floor and can reveal artifacts; large positive gains risk amplifying noise or causing clipping. Review computed gains (dry-run) before bulk processing.
- Test on a small sample first.
- If files have multiple audio streams, scripts apply filters to the default audio stream; modify ffmpeg arguments to target specific streams if needed.
- Back up originals if you must preserve unmodified files before normalization.

Examples
- Normalize to loudest peak and convert to MP4 with CRF 18 and preset slow: run ConvertBatchVolumeMax.ps1, set format to mp4, CRF 18, preset slow.
- Normalize to average peak, write normalized copies to .\TEMP for review, then run ConvertBatch_v2.ps1 with IN set to .\TEMP.


