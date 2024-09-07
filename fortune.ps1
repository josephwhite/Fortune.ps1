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
      {
        "default": [
          "C:\\foobar\\fortunes\\*",
        ],
        "TV": [
          "C:\\foobar\\fortunes\\xfiles",
          "C:\\foobar\\fortunes\\breakingbad.txt"
        ]
      }
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
    .PARAMETER Percentage
    Prints an array of fortune filepaths, thier percentages, and terminates if present.
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
    Just print filepaths and percentages.
    fortune.ps1 -Percentage
    fortune.ps1 -Percentage -Group Foo
    fortune.ps1 -p -File 'C:\foorbar\fortunes\*'
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
                - v0.3.0+ supports PowerShell v5.1+
                - v0.2.0 supports PowerShell v7.2+ (not recommended)
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
    [Alias("m", "regex")]
    [AllowEmptyString()]
    [string]$Match,

    [Parameter()]
    [Alias("p")]
    [switch]$Percentage,

    [Parameter()]
    [Alias("h")]
    [switch]$Help
)

<#
    .SYNOPSIS
    Converts a Fortune file to an array of Fortunes.
    .PARAMETER FortuneFile
    Path of Fortune file.
    .PARAMETER Group
    Group if Fortune file was found through Group/Config.
#>
function Get-FortuneFromFile {
    param(
        [string]$FortuneFile,
        [string]$Group = $NULL
    )
    $fortunes_from_file = @()
    # Get each fortune file from path with wildcard.
    $FortuneFileItem = Get-Item -Path $FortuneFile
    Foreach ($path in $FortuneFileItem) {
        $fortune_vmes = "Compiling fortunes from {0}" -f $path
        Write-Verbose -Message ($fortune_vmes)
        $fortunes_from_file_buffer = (Get-Content -Path $path -Raw) -replace "`r`n", "`n" -split "`n%`n"
        $fortunes_from_file += Foreach ($entry in $fortunes_from_file_buffer) {
            [PSCustomObject] @{
                Fortune = $entry
                Path    = $path.Fullname
                Group   = $Group
            }
        }
    }
    return $fortunes_from_file
}

<#
    .SYNOPSIS
    Converts a group of Fortune files to an array of Fortunes.
    .PARAMETER Tag
    Group of Fortune files.
    .PARAMETER ConfigObj
    Object representation of Config file to pull Tag from.
    Previously used System.Object type to support multiple config formats and how they are imported to PowerShell.
        TOML -> OrderedDictionary
             -> OrderedDictionary -> Hashtable (https://stackoverflow.com/a/48679838)
        JSON -> PSCustomObject
             -> OrderedHashtable -> Hashtable (Using -AsHashtable in PowerShell v7.3.0-preview.6+)
             -> PSCustomObject -> Hashtable (https://stackoverflow.com/a/32102005)
        PDS1 -> Hashtable
    System.Object is the BaseType of Hashtable, OrderedDictionary, and PSCustomObject.
#>
function Get-FortuneFromFileCollection {
    param(
        [string]$Tag,
        [System.Collections.Hashtable]$ConfigObj
    )
    $FilesInGroup = $ConfigObj.$Tag
    $fortunes_from_files = @()
    Foreach ($path in $FilesInGroup) {
        $fortunes_from_files_buffer = Get-FortuneFromFile -FortuneFile $path -Group $Tag
        $fortunes_from_files += $fortunes_from_files_buffer
    }

    return $fortunes_from_files
}

<#
    .SYNOPSIS
    Filter an array of Fortunes by character length.
    .PARAMETER Fortunes
    Array of Fortunes to filter.
    .PARAMETER Long
    Filter for fortunes that are longer than the given character length if present.
    .PARAMETER Short
    Filter for fortunes that are shorter than the given character length if present.
    .PARAMETER Length
    Filter for fortunes with the given character length if present.
#>
function Select-FortunesByLength {
    param(
        [PSCustomObject[]]$Fortunes,
        [int]$Long,
        [int]$Short,
        [int]$Length
    )
    $fortune_count_before = $Fortunes.Count
    if ($Long) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune.Length -ge $Long
        }
    }
    if ($Short) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune.Length -le $Short
        }
    }
    if ($Length) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune.Length -eq $Length
        }
    }
    $fortune_count_after = $Fortunes.Count
    $fortune_vmes = "{0} to {1} fortune(s) after length filter." -f $fortune_count_before, $fortune_count_after
    Write-Verbose -Message ($fortune_vmes)

    return $Fortunes
}

<#
    .SYNOPSIS
    Filter an array of Fortunes by character matching.
    .PARAMETER Fortunes
    Array of Fortunes to filter.
    .PARAMETER Pattern
    Filter and prints fortunes matching a given REGEX pattern.
#>
function Select-FortunesByPattern {
    param(
        [PSCustomObject[]]$Fortunes,
        [string]$Pattern
    )
    $fortune_count_before = $Fortunes.Count
    if ($Pattern) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune -match $Pattern
        }
    }
    $fortune_count_after = $Fortunes.Count
    $fortune_vmes = "{0} to {1} fortune(s) after pattern filter." -f $fortune_count_before, $fortune_count_after
    Write-Verbose -Message ($fortune_vmes)

    return $fortunes
}

<#
    .SYNOPSIS
    Output a random Fortune from an array.
    .PARAMETER Fortunes
    Array of Fortunes.
#>
function Show-Fortune {
    param(
        [PSCustomObject[]]$Fortunes
    )
    $final_fortune = $Fortunes | Get-Random
    Write-Output $final_fortune.Fortune

    return
}

<#
    .SYNOPSIS
    Output each Fortune in an array, delimited by "%"
    .PARAMETER Fortunes
    Array of Fortunes.
#>
function Show-PossibleFortuneList {
    param(
        [PSCustomObject[]]$Fortunes
    )
    foreach ($entry in $Fortunes) {
        Write-Output $entry.Fortune
        Write-Output "%"
    }

    return
}

<#
    .SYNOPSIS
    Output the unique Fortune Filepaths and the chance a Fortune would be picked from each file.
    .PARAMETER Fortunes
    Array of Fortunes.
#>
function Show-FortunePercentageByFile {
    param(
        [PSCustomObject[]]$Fortunes
    )
    $total_count = $Fortunes.Count
    # Aggregate the unique Fortune Files
    $unique_paths = $Fortunes | Sort-Object -Unique -Property Path | Select-Object -Property Path
    # Calculate Percentage for each unique path
    $unique_paths | Add-Member -NotePropertyName Percentage -NotePropertyValue 0.0
    foreach ($path in $unique_paths) {
        $subsection = $Fortunes | Where-Object { $_.Path -eq $path.Path; }
        $path.Percentage = [double]($subsection.Count / $total_count) * 100
    }
    $unique_paths
}

if ($Help) {
    Get-Help $PSCommandPath
    Write-Output ""
    $h1 = "
  Run the following command for full documentation.
    Get-Help $PSCommandPath -Full
"
    Write-Output $h1
    exit 0
}

# Parameter Priority Logic
#    File is above Group
#    Length is above Long and Short
if ($File -and $Group) {
    $Group = $NULL
    $Config = $NULL
}

if ($Length) {
    $Short = $NULL
    $Long = $NULL
}

if ($File) {
    # Validation: File not a valid path
    if (!(Test-Path($File))) {
        Write-Error -Message "Fortune file not found or invalid path." -Category ReadError
        exit 1
    }
    $f = Get-FortuneFromFile -FortuneFile $File
    $f = Select-FortunesByLength -Fortunes $f -Long $Long -Short $Short -Length $Length
    $f = Select-FortunesByPattern -Fortunes $f -Pattern $Match

    if ($Percentage) {
        Show-FortunePercentageByFile -Fortunes $f
        exit 0
    }

    if ($Match) {
        Show-PossibleFortuneList -Fortunes $f
        $fortune_count = $f.Count
        $fortune_vmes = "{0} fortune(s) matching pattern {1}" -f $fortune_count, $Match
        Write-Verbose -Message ($fortune_vmes)
        exit 0
    }

    Show-Fortune -Fortunes $f

    exit 0
}

if ($Group) {
    # Validation: File not a valid path
    if (!(Test-Path($Config))) {
        Write-Error -Message "Config file not found or invalid path." -Category ReadError
        exit 1
    }
    # Get data from config file.
    $config_file_ext = ((Get-Item $Config).Extension).ToUpper()
    switch ($config_file_ext) {
        ".TOML" {
            $cfg = Get-Content -Path $Config | ConvertFrom-Toml
            $cfg = [hashtable]$cfg
        }
        ".JSON" {
            $cfg_buffer = Get-Content -Path $Config -Raw | ConvertFrom-Json
            # Convert from PSCustomObject to Hashtable type
            # Using this method to be compatible with PowerShell prior v7.3.0
            $cfg = @{}
            $cfg_buffer | Get-Member -MemberType Properties | ForEach-Object {
                $cfg.Add($_.Name, $cfg_buffer.($_.Name))
            }
        }
        ".PSD1" {
            $cfg = Import-PowerShellDataFile -Path $Config -SkipLimitCheck
        }
        default {
            Write-Error -Message "Config file type not supported." -Category InvalidType
            exit 1
        }
    }
    $f = Get-FortuneFromFileCollection -Tag $Group -ConfigObj $cfg
    $f = Select-FortunesByLength -Fortunes $f -Long $Long -Short $Short -Length $Length
    $f = Select-FortunesByPattern -Fortunes $f -Pattern $Match

    if ($Percentage) {
        Show-FortunePercentageByFile -Fortunes $f
        exit 0
    }

    if ($Match) {
        Show-PossibleFortuneList -Fortunes $f
        $fortune_count = $f.Count
        $fortune_vmes = "{0} fortune(s) matching pattern {1}" -f $fortune_count, $Match
        Write-Verbose -Message ($fortune_vmes)
        exit 0
    }

    Show-Fortune -Fortunes $f

    exit 0
}

exit 0
