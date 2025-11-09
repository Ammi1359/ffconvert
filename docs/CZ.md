Napsal Nuru — 2025
Přehled
- Tato kolekce obsahuje hlavní PowerShell skript pro hromadnou konverzi videí a dva pomocné skripty pro normalizaci hlasitosti (peak-max a průměr). Vše používá FFmpeg a je určeno pro Windows. Soubory se konvertují, zachovává se strom složek, po úspěšné konverzi se původní soubory přesunou do složky Done.

REPO:
https://github.com/Ammi1359/ffconvert

Soubory ve sbírce
- ConvertBatch_v2.ps1 — hlavní konvertor
Rekurzivně prohledá IN, zachovává relativní podsložky v OUT, konvertuje do zvoleného formátu, přesune originály do Done, zobrazuje průběh a barevné logy. Ptá se na formát, CRF a preset.
- ConvertBatchVolumeMax.ps1 — normalizace na nejhlasitější soubor
Měří max_volume pomocí ffmpeg -af volumedetect, jako cíl vezme nejvyšší naměřenou hodnotu a pro každý soubor spočítá gain = target − current, aplikuje -filter:a "volume=XdB" při konverzi, zachovává strukturu složek a přesouvá originály do Done.
- ConvertBatchVolumeAverage.ps1 — normalizace na průměr
Měří max_volume pro všechny soubory, spočítá aritmetický průměr platných měření jako cílovou hodnotu a aplikuje stejný gain na všechny soubory. Konverze a přesun originálů stejné jako u ostatních skriptů.

Požadavky
- PowerShell na Windows (doporučeno spustit jako Administrátor).
- FFmpeg (ffmpeg.exe) dostupný v PATH nebo nastavte plnou cestu v proměnné $ffmpeg v hlavičce skriptů.
Doporučené zdroje: https://ffmpeg.org/download.html

Struktura složek a podporované formáty
- .\IN → vložte vstupní videa (skripty skenují rekurzivně a zachovávají relativní podsložky).
- .\OUT → zde budou výsledné soubory, struktura odpovídá IN.
- .\Done → originály budou po úspěšné konverzi přesunuty sem, struktura odpovídá IN.
- Volitelné .\TEMP → použijte, pokud chcete, aby normalizátory zapisovaly mezivýstupy pro kontrolu.
Podporované vstupní přípony: .mkv, .mp4, .avi, .mpg (rekurzivně).

Volby při spuštění a výchozí chování
- Výstupní formát: mp4, avi, mov, webm (výchozí mp4).
- CRF: kvalita pro x264 (výchozí 18; běžně 18–28). Nižší = lepší kvalita.
- Preset: rychlost vs. komprese (výchozí slow; platné hodnoty: ultrafast … veryslow).
- Výchozí kodeky v skriptech: video libx264, audio aac 192k.
- Normalizátory používají volumedetect a hodnotu max_volume.
- Normalizátory obsahují přepínač $DoConvert — nastavte $false pro dry-run (vypočítat a nahlásit gainy bez spuštění ffmpeg).

Doporučené postupy (workflows)
- Umístěte zdrojová videa do .\IN (ponechte podsložky, pokud chcete zachovat strukturu).
- Zvolte strategii normalizace:
- ConvertBatchVolumeMax.ps1 — srovná vrcholy na nejhlasitější soubor (per-soubor gain).
- ConvertBatchVolumeAverage.ps1 — srovná všechny soubory na aritmetický průměr (jednotná úprava).
- Možnosti nasazení:
- Bezpečně: nechte normalizátor zapisovat do .\TEMP, zkontrolujte výstupy a poté spusťte ConvertBatch_v2.ps1 s IN = TEMP.
- In-place: normalizátor přepíše .\IN, poté spusťte ConvertBatch_v2.ps1.
- Spusťte konvertor nebo normalizátor (oba mohou provádět konverzi) a odpovězte na výzvy ohledně formátu/CRF/presetu.
- Ověřte vzorky v .\OUT a zkontrolujte, že originály jsou v .\Done.

Upozornění a tipy
- Peak-based normalizace (volumedetect) srovnává vrcholy, ne vnímanou hlasitost (LUFS). Pro konzistentní vnímanou hlasitost mezi různým obsahem použijte LUFS (ffmpeg loudnorm dvoufázově).
- Pozitivní gainy zvyšují hladinu šumu a mohou odhalit artefakty; velké pozitivní zisky mohou způsobit slyšitelný šum nebo clipping. Před hromadným zpracováním si prohlédněte vypočtené gainy (dry-run).
- Otestujte na malém vzorku.
- Pokud mají vstupní soubory více audio stop, skripty upravují výchozí audio stopu; upravte ffmpeg argumenty, pokud potřebujete cílit přesně.
- Pokud chcete zachovat originály beze změny, zálohujte je před normalizací.

Příklady použití
- Normalizovat na nejhlasitější vrchol a konvertovat do MP4 s CRF 18 a preset slow: spusťte ConvertBatchVolumeMax.ps1, nastavte formát mp4, CRF 18, preset slow.
- Normalizovat na průměr, uložit normované kopie do .\TEMP pro kontrolu, poté spustit ConvertBatch_v2.ps1 s IN = .\TEMP.


