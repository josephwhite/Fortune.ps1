<#
  .SYNOPSIS
  PowerShell implementation of the Fortune program.
  .PARAMETER File
  Filepath of fortune file(s) to pool from when not using a group and config file. Wildcards are supported.
  Takes priority over Group flag.
  .PARAMETER Config
  Filepath of configuration file defining groups of Fortune files and their filepaths.

  Accepted configuration file formats:
  - JSON (JavaScript Object Notation)
  - TOML (Tom's Obvious, Minimal Language)
  - PSD1 (PowerShell data file)

  If absent and using the Group flag (-Group, -g), config will be checked for in ($PSScriptRoot + "\fortune_config.psd1").
  Config will be ignored if using File flag (-File, -f).
  Config file must contain a grouping labelled "default" if no Group flag is provided.

  Example format of fortune_config.toml
  ```toml
    default = [
      "C:\foobar\fortunes\*",
    ]
    TV = [
      "C:\foobar\fortunes\xfiles",
      "C:\foobar\fortunes\breakingbad.txt"
    ]
  ```
  Example format of fortune_config.json
  ```json
    "default": [
      "C:\\foobar\\fortunes\\*",
    ],
    "TV": [
      "C:\\foobar\\fortunes\\xfiles",
      "C:\\foobar\\fortunes\\breakingbad.txt"
    ]
  ```
  Example format of fortune_config.psd1
  ```psd1
    @{
      default = @(
        'C:\foobar\fortunes\*',
      )
      TV = @(
        "C:\foobar\fortunes\xfiles"
        "C:\foobar\fortunes\breakingbad.txt"
      )
    }
  ```
  .PARAMETER Group
  Group of filepaths to pool fortunes from.
  Default value is "default"
  .PARAMETER Long
  Filter for fortunes that are longer than the given character length if present.
  Should be a positive real number.
  See: https://proofwiki.org/wiki/Definition:Positive/Real_Number
  .PARAMETER Short
  Filter for fortunes that are shorter than the given character length if present.
  Should be a positive real number.
  See: https://proofwiki.org/wiki/Definition:Positive/Real_Number
  .PARAMETER Length
  Filter for fortunes with the given character length if present.
  Takes priority over Long and Short flags.
  Should be a positive real number.
  See: https://proofwiki.org/wiki/Definition:Positive/Real_Number
  .PARAMETER Match
  Filter and prints fortunes matching a given REGEX pattern.
  Each fortune will be seperated by a single %.
  .PARAMETER Help
  Prints Full Get-Help output and terminates if present.
  .EXAMPLE
  fortune.ps1
  .EXAMPLE
  fortune.ps1 -File 'C:\foorbar\fortunes\motivation.txt'
  fortune.ps1 -f 'C:\foorbar\fortunes\*'
  .EXAMPLE
  fortune.ps1 -Group 'TV'
  .EXAMPLE
  fortune.ps1 -Config 'C:\foobar\cfg\fortune_config.toml'
  .EXAMPLE
  fortune.ps1 -g 'TV' -c 'C:\foobar\cfg\fortune_config.json'
  .EXAMPLE
  Filter for fortunes that are between 20-50 characters long.
  fortune.ps1 -Long 20 -Short 50
  fortune.ps1 -l 20 -s 50
  .EXAMPLE
  Filter for fortunes that are exactly 30 characters long.
  fortune.ps1 -Length 30
  fortune.ps1 -n 30
  fortune.ps1 -ls 30
  .EXAMPLE
  fortune.ps1 -Match foo
  fortune.ps1 -m *bar*
  fortune.ps1 -regex [0-9][0-9]
  .EXAMPLE
  fortune.ps1 -Help
  fortune.ps1 -h
  .EXAMPLE
  Verbose messaging is available.
  fortune.ps1 -Verbose
  .NOTES
  Version
    1.0.0
  Dependencies
    - PSToml
      - Needed to parse TOML files.
      - https://www.powershellgallery.com/packages/PSToml/
        - 0.3.0 supports PowerShell v5.1+
        - 0.2.0 supports PowerShell v7.2+ (not recommended)
#>
param(
  [Parameter()]
  [Alias("f")]
  [AllowEmptyString()]
  [string]$File,

  [Parameter()]
  [Alias("g")]
  [AllowEmptyString()]
  [string]$Group = "default",

  [Parameter()]
  [Alias("c")]
  [AllowEmptyString()]
  [string]$Config = $PSScriptRoot + "\fortune_config.psd1",

  [Parameter()]
  [Alias("l")]
  [int]$Long,

  [Parameter()]
  [Alias("s")]
  [int]$Short,

  [Parameter()]
  [Alias("ls", "n")]
  [int]$Length,

  [Parameter()]
  [Alias("m","regex")]
  [AllowEmptyString()]
  [string]$Match,

  [Parameter()]
  [Alias("h")]
  [switch]$Help
)

function Get-FortuneFromFile ($fortuneFile) {
  $fortune_vmes = "Compiling fortunes from {0}" -f $fortuneFile;
  Write-Verbose -Message ($fortune_vmes);
  $fortunes_from_file = (Get-Content -Path $fortuneFile -raw) -replace "`r`n", "`n" -split "`n%`n";

  return $fortunes_from_file;
}

function Get-FortuneFromFileCollection($tag, [System.Object]$c) {
  $fortunes_from_files = @();
  Foreach ($path in $c.$tag) {
    $fortunes_from_files_buffer = Get-FortuneFromFile($path);
    $fortunes_from_files += $fortunes_from_files_buffer;
  }

  return $fortunes_from_files;
}

function Select-FortunesByLength($fortunes) {
  $fortune_count_before = $fortunes.Count;
  if ($Long) {
    $fortunes = $fortunes | Where-Object {
      $_.Length -ge $Long;
    }
  }
  if ($Short) {
    $fortunes = $fortunes | Where-Object {
      $_.Length -le $Short;
    }
  }
  if ($Length) {
    $fortunes = $fortunes | Where-Object {
      $_.Length -eq $Length;
    }
  }
  $fortune_count_after = $fortunes.Count;
  $fortune_vmes = "{0} to {1} fortune(s) after length filter." -f $fortune_count_before, $fortune_count_after;
  Write-Verbose -Message ($fortune_vmes);

  return $fortunes;
}

function Select-FortunesByPattern($fortunes) {
  $fortune_count_before = $fortunes.Count;
  if ($Match) {
    $fortunes = $fortunes | Where-Object {
      $_ -match $Match;
    }
  }
  $fortune_count_after = $fortunes.Count;
  $fortune_vmes = "{0} to {1} fortune(s) after pattern filter." -f $fortune_count_before, $fortune_count_after;
  Write-Verbose -Message ($fortune_vmes);

  return $fortunes;
}


function Show-Fortune($fortunes) {
  $final_fortune = $fortunes | Get-Random;
  Write-Output $final_fortune;

  return;
}

function Show-PossibleFortuneList($fortunes) {
  foreach ($entry in $fortunes) {
    Write-Output $entry;
    Write-Output "%";
  }
  $fortune_count = $fortunes.Count;
  $fortune_vmes = "{0} fortune(s) matching pattern {1}" -f $fortune_count, $Match;
  Write-Verbose -Message ($fortune_vmes);

  return;
}

if ($Help) {
  Get-Help $PSCommandPath;
  Write-Output "";
  $h1 = "
  Run the following command for full documentation.
    Get-Help $PSCommandPath -Full
  "
  Write-Output $h1;
  exit 0;
}

# Parameter Priority Logic
#    File is above Group
#    Length is above Long and Short
if ($File -and $Group) {
  $Group = $NULL;
}

if ($Length) {
  $Short = $NULL;
  $Long = $NULL;
}

if ($File) {
  # Validation: File not a valid path
  if (!(Test-Path($File))) {
    Write-Error -Message "Fortune file not found or invalid path." -Category ReadError;
    exit 1;
  }
  $f = Get-FortuneFromFile($File);
  $f = Select-FortunesByLength($f);
  if ($Match) {
    $f = Select-FortunesByPattern($f);
    Show-PossibleFortuneList($f);
  } else {
    Show-Fortune($f);
  }
  exit 0;
}

if ($Group) {
  # Validation: File not a valid path
  if (!(Test-Path($Config))) {
    Write-Error -Message "Config file not found or invalid path." -Category ReadError;
    exit 1;
  }
  # Get data from config file.
  $config_file_ext = ((Get-Item $Config).Extension).ToUpper()
  switch($config_file_ext) {
    ".TOML" {
      $cfg = Get-Content -Path $Config | ConvertFrom-Toml;
    }
    ".JSON" {
      $cfg = Get-Content -Raw -Path $Config | ConvertFrom-Json;
    }
    ".PSD1" {
      $cfg = Import-PowerShellDataFile $Config;
    }
    default {
      Write-Error -Message "Config file type not supported." -Category InvalidType;
      exit 1;
    }
  }
  $f = Get-FortuneFromFileCollection $Group $cfg;
  $f = Select-FortunesByLength($f);
  if ($Match) {
    $f = Select-FortunesByPattern($f);
    Show-PossibleFortuneList($f);
  } else {
    Show-Fortune($f);
  }
  exit 0;
}

exit 0;