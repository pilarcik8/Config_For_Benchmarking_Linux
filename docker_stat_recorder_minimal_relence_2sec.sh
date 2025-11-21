$outputFile = "C:\Users\Admin\Desktop\vysledok\docker_stats.csv"

# Vytvor priečinok ak neexistuje
$folder = Split-Path $outputFile
if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }

# Header iba ak súbor neexistuje alebo je prázdny
if (-not (Test-Path $outputFile) -or (Get-Content $outputFile | Measure-Object -Line).Lines -eq 0) {
    "HH:mm:ss.fff;CPU%;CPU_frac;MemUsage;MemUsage_MB;Mem%" | Out-File $outputFile -Encoding utf8
}

while ($true) {
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    
    # Získaj raw hodnoty
    $stats = docker stats --no-stream --format "{{.CPUPerc}};{{.MemUsage}};{{.MemPerc}}"
    $parts = $stats -split ";"

    $cpuPerc = $parts[0]            # napr. 31.0%
    $memUsageRaw = $parts[1]        # napr. 2.262MiB / 3.678GiB
    $memPerc = $parts[2]            # napr. 0.06%

    # CPU percent → desatinné číslo
    $cpuFrac = [math]::Round(([double]($cpuPerc.TrimEnd('%')) / 100), 4)

    # MemUsage na MB
    $memUsed = $memUsageRaw -split " / " | Select-Object -First 1   # "2.262MiB"
    if ($memUsed -match "([0-9.]+)([KMG]i?)B") {
        $num = [double]$matches[1]
        $unit = $matches[2]
        switch ($unit) {
            "Ki" { $memMB = [math]::Round($num / 1024, 3) }
            "Mi" { $memMB = [math]::Round($num, 3) }
            "Gi" { $memMB = [math]::Round($num * 1024, 3) }
            default { $memMB = $num }
        }
    } else { $memMB = 0 }

    # Zapíš do CSV
    "$timestamp;$cpuPerc;$cpuFrac;$memUsageRaw;$memMB;$memPerc" | Out-File $outputFile -Append -Encoding utf8

    Start-Sleep -Seconds 0
}
