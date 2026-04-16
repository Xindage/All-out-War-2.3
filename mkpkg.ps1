<#
.SYNOPSIS
    Windows equivalent of mkpkg.sh — builds AOW2.3 PK3 packages.
.DESCRIPTION
    Compiles ACS source and packages game assets into PK3 files (stored ZIP archives).
    Use -CompileOnly to only rebuild the code package.
.EXAMPLE
    .\mkpkg.ps1
    .\mkpkg.ps1 -CompileOnly
#>
param(
    [switch]$CompileOnly,
    [switch]$SkipCompile,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# --- Config ---
$ACC = "C:\Users\ac3de\Games\Doom\Ultimate Doombuilder\Compilers\Zandronum\acc.exe"
$ACS_SRC = "source\aow2scrp.acs"
$ACS_OUT = "acs\aow2scrp.o"
$OutDir  = "OUTPUT"

# --- Date stamp ---
$vardate = Get-Date -Format "yyMMdd"
Write-Host "Date stamp: $vardate"

# --- Ensure output directory ---
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# --- Helper: create a PK3 (stored ZIP, no compression) from a list of glob patterns ---
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-PK3 {
    param(
        [string]$OutputPath,
        [string[]]$Patterns
    )

    # Remove existing file
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

    $fullPath = Join-Path (Get-Location).Path $OutputPath
    $zip = [System.IO.Compression.ZipFile]::Open(
        $fullPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )

    try {
        $baseDir = (Get-Location).Path
        $added = @{}

        foreach ($pattern in $Patterns) {
            # Determine if it's a directory glob (ends with /*) or a single file
            $items = @()
            if ($pattern -match '[/\\]\*$') {
                # Directory recursive pattern like "acs/*"
                $dir = $pattern -replace '[/\\]\*$', ''
                if (Test-Path $dir) {
                    $items = Get-ChildItem -Path $dir -Recurse -File
                }
            } else {
                # Single file pattern
                if (Test-Path $pattern) {
                    $items = Get-Item $pattern | Where-Object { -not $_.PSIsContainer }
                } else {
                    # Try wildcard (e.g. sndinfo*)
                    $items = Get-ChildItem -Path "." -Filter $pattern -File -ErrorAction SilentlyContinue
                }
            }

            foreach ($file in $items) {
                $relPath = $file.FullName.Substring($baseDir.Length + 1) -replace '\\', '/'
                if (-not $added.ContainsKey($relPath)) {
                    # Store mode = NoCompression
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                        $zip, $file.FullName, $relPath,
                        [System.IO.Compression.CompressionLevel]::NoCompression
                    ) | Out-Null
                    $added[$relPath] = $true
                }
            }
        }
    }
    finally {
        $zip.Dispose()
    }

    $count = $added.Count
    Write-Host "  -> $OutputPath ($count files)"
}

# --- Compile ACS ---
function Invoke-ACC {
    if ($SkipCompile) {
        Write-Host "Skipping ACS compilation (-SkipCompile)." -ForegroundColor Yellow
        return
    }
    Write-Host "Compiling ACS..."
    & $ACC $ACS_SRC $ACS_OUT
    if ($LASTEXITCODE -ne 0) {
        if ($Force) {
            Write-Host "ACS compilation failed (continuing with -Force)." -ForegroundColor Yellow
        } else {
            Write-Host "ACS compilation failed! Use -Force to continue anyway." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "ACS source was compiled successfully!" -ForegroundColor Green
    }
}

# --- Code package file list ---
$codeFiles = @(
    "cvarinfo.txt", "decorate.txt", "gameinfo.txt", "keyconf.txt",
    "changelog_gaturra.txt", "main_changelog.txt",
    "gldefs.txt", "language.txt", "loadacs.txt", "teaminfo.txt",
    "acs/*", "source/*", "actors/*", "credits/*"
)

if ($CompileOnly) {
    # --- Compile-only mode ---
    Write-Host "=== Compile-only mode ==="
    # Clean old code packages
    Get-ChildItem "$OutDir\aow2.3_code_r*" -ErrorAction SilentlyContinue | Remove-Item -Force

    Invoke-ACC

    Write-Host "Generating code package..."
    New-PK3 "$OutDir\aow2.3_code_r$vardate.pk3" $codeFiles
}
else {
    # --- Full build ---
    Write-Host "=== Full build ==="
    Write-Host "Cleaning old data..."
    Get-ChildItem "$OutDir\*" -ErrorAction SilentlyContinue | Remove-Item -Force

    # Data package
    Write-Host "Generating data package..."
    $dataFiles = @(
        "animdefs.txt", "colormap.dat", "dbigfont.lmp", "decaldef.txt",
        "fontdefs.txt", "hirestex.txt", "hirestex.weapons.txt", "modeldef.txt",
        "notch.dat", "playpal.pal", "sbarinfo.txt", "skininfo.txt",
        "sndinfo*", "sndseq.txt", "startup.dat", "terrain.txt",
        "textures.*.txt", "textures.txt",
        "textures/*", "sprites/*", "sounds/*", "patches/*",
        "models/*", "graphics/*", "flats/*"
    )
    New-PK3 "$OutDir\aow2.3_data_r$vardate.pk3" $dataFiles

    # Code package
    Invoke-ACC

    Write-Host "Generating code package..."
    New-PK3 "$OutDir\aow2.3_code_r$vardate.pk3" $codeFiles

    # Maps package
    Write-Host "Generating maps package..."
    New-PK3 "$OutDir\aow2.3_maps_r$vardate.pk3" @("mapinfo.txt", "maps/*", "credmaps/*")

    # Music package
    Write-Host "Generating music package..."
    New-PK3 "$OutDir\aow2.3_music_r$vardate.pk3" @("music/*", "credmus/*")
}

Write-Host "`nDone!" -ForegroundColor Green
