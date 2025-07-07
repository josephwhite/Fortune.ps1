<#PSScriptInfo
.VERSION 1.0.6
.GUID 0e2718fa-6a3f-426d-9378-beed592e39ff
.AUTHOR isthisfieldimportant
#>
<#
    .SYNOPSIS
    PowerShell implementation of the Fortune program.
    .DESCRIPTION
    Fortune for PowerShell that includes flexible file selecting, config support, and various parameters from the original Fortune.
    .PARAMETER File
    [System.String]
    Filepath of fortune file(s) to pool from when not using a group and config file. Wildcards are supported.
    Takes priority over Group flag.
    .PARAMETER Config
    [System.String]
    Filepath of configuration file defining groups of Fortune files and their filepaths.

    Accepted configuration file formats:
    - JSON (JavaScript Object Notation)
    - JSONC (JSON with Comments)
    - TOML (Tom's Obvious, Minimal Language)
    - YAML (Yet Another Markup Language / YAML Ain't Markup Language)
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
    Example format of fortune_config.yaml
    ```yaml
    default:
        - 'C:\foobar\fortunes\*'
    TV:
        - 'C:\foobar\fortunes\xfiles'
        - 'C:\foobar\fortunes\breakingbad.txt'
    ```
    .PARAMETER Group
    [System.String]
    Group of filepaths to pool fortunes from.
    Default value is "default"
    .PARAMETER Long
    [System.Int32]
    Filter for fortunes that are longer than the given character length if present.
    Should be a positive integer.
    See: https://proofwiki.org/wiki/Definition:Positive/Integer
    .PARAMETER Short
    [System.Int32]
    Filter for fortunes that are shorter than the given character length if present.
    Should be a positive integer.
    See: https://proofwiki.org/wiki/Definition:Positive/Integer
    .PARAMETER Length
    [System.Int32]
    Filter for fortunes with the given character length if present.
    Takes priority over Long and Short flags.
    Should be a positive integer.
    See: https://proofwiki.org/wiki/Definition:Positive/Integer
    .PARAMETER Equidistribution
    [System.Management.Automation.SwitchParameter]
    Give each fortune file found an equal probability of having their fortune being printed.
    Replaces being relative to the entries of each file.
    .PARAMETER Match
    [System.String]
    Filter and prints fortunes matching a given REGEX pattern.
    Each fortune will be separated by a single %.
    .PARAMETER Percentage
    [System.Management.Automation.SwitchParameter]
    Prints an array of fortune filepaths, their percentages, and terminates if present.
    .PARAMETER Seed
    [System.Int32]
    Sets seed for randomization.
    Will not affect Get-Random calls outside script.
    .PARAMETER Wait
    [System.Management.Automation.SwitchParameter]
    Waits before exiting after printing single fortune.
    .PARAMETER Version
    [System.Management.Automation.SwitchParameter]
    Prints version and terminates if present.
    .PARAMETER Help
    [System.Management.Automation.SwitchParameter]
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
    Make the probability of choosing a fortune file equal to that of all other files.
    fortune.ps1 -File 'C:\foorbar\fortunes\*' -Equidistribution
    fortune.ps1 -Group 'TV' -Equidistribution
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

    Equally distribute percentages.
    fortune.ps1 -Percentage -Group Foo -Equidistribution
    .EXAMPLE
    fortune.ps1 -Wait
    .EXAMPLE
    Print version and exit.
    fortune.ps1 -Version
    fortune.ps1 -v
    .EXAMPLE
    Print help and exit.
    fortune.ps1 -Help
    fortune.ps1 -h
    .EXAMPLE
    Verbose messaging is available.
    fortune.ps1 -Verbose
    .NOTES
    Dependencies
        - PSToml
            - Needed to parse TOML files.
            - Github: https://github.com/jborean93/PSToml
            - PowerShell Gallery: https://www.powershellgallery.com/packages/PSToml/
            - Compatability by version:
                - v0.4.0 supports PowerShell v5.1 & v7.4+
                - v0.3.x supports PowerShell v5.1+
                - v0.2.0 supports PowerShell v7.2+ (not recommended)
        - powershell-yaml
            - Needed to parse YAML files.
            - Github: https://github.com/cloudbase/powershell-yaml
            - PowerShell Gallery: https://www.powershellgallery.com/packages/powershell-yaml/
             - Compatability by version:
                - v0.4.8+ supports PowerShell v5.0+
                - v0.4.7 supports PowerShell v3.0+

    Blame
        - Using .NET's [System.Random]
            - Usage of Seed parameter WITHOUT affecting Get-Random seed outside of the script
            - Get-Random doesn't support a flag for clearing set seeds
                - "You can't reset the seed to its default value"
                    - https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/get-random
            - We have to use the .NET Framework 4.5 [System.Random] class and functions to stay compatible with Windows PowerShell
        - Creating a subcopy of the script in temp path
            - PSScriptInfo seems to cause issues for Get-Help
            - https://stackoverflow.com/q/71579241
        - Converting PSCustomObject to Hashtable type for JSON configs
            - General "want" to have the basetype of all imported configs to be more specific than System.Object
            - Using this method to be compatible with PowerShell prior v7.3.0
                - AsHashtable for ConvertFrom-Json was introduced in v7.3.0
            - https://stackoverflow.com/a/32102005

#>
[CmdletBinding()]
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
    [string]$Config = $PSScriptRoot + '\fortune_config.psd1',

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
    [Alias("e")]
    [switch]$Equidistribution,

    [Parameter()]
    [Alias("m", "regex")]
    [AllowEmptyString()]
    [string]$Match,

    [Parameter()]
    [Alias("p")]
    [switch]$Percentage,

    [Parameter()]
    [int]$Seed,

    [Parameter()]
    [Alias("w")]
    [switch]$Wait,

    [Parameter()]
    [Alias("v")]
    [switch]$Version,

    [Parameter()]
    [Alias("h")]
    [switch]$Help
)

class FortuneConfig {
    [System.IO.FileInfo]$Path
    [ValidateSet("PSD1", "JSON", "TOML", "YAML")]
    [string]$Type
    [System.Collections.Hashtable]$Data

    FortuneConfig() {
        throw "FortuneConfig needs a path and valid type."
    }
    FortuneConfig([System.IO.FileInfo]$Path) {
        throw "FortuneConfig needs a valid type."
    }
    FortuneConfig([string]$Type) {
        throw "FortuneConfig needs a path."
    }
    FortuneConfig([System.IO.FileInfo]$Path, [string]$Type) {
        switch ($Type) {
            "TOML" {
                $cfg_buffer = Get-Content -Path $Path | ConvertFrom-Toml
                $this.Data = [hashtable]$cfg_buffer
                $this.Type = $Type
                $this.Path = $Path
            }
            "YAML" {
                $this.Data = Get-Content -Path $Path | ConvertFrom-Yaml
                $this.Type = $Type
                $this.Path = $Path
            }
            "JSON" {
                $cfg_buffer = Get-Content -Path $Path -Raw
                # Strip comments to allow Windows PowerShell to use JSONC
                $cfg_buffer = $cfg_buffer -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*'
                $cfg_buffer = $cfg_buffer -replace '(?ms)/\*.*?\*/'
                $cfg_buffer = $cfg_buffer | ConvertFrom-Json
                # Convert from PSCustomObject to Hashtable type
                $this.Data = @{}
                $cfg_buffer | Get-Member -MemberType Properties | ForEach-Object {
                    $this.Data.Add($_.Name, $cfg_buffer.($_.Name))
                }
                $this.Type = $Type
                $this.Path = $Path
            }
            "PSD1" {
                # Use -SkipLimitCheck if available (<= PowerShell v7.2)
                if ((Get-Variable PSVersionTable -ValueOnly).PSVersion -ge [version]7.2) {
                    $this.Data = Import-PowerShellDataFile -Path $Path -SkipLimitCheck
                }
                else {
                    $this.Data = Import-PowerShellDataFile -Path $Path
                }
                $this.Type = $Type
                $this.Path = $Path
            }
            default {
                throw "FortuneConfig needs a valid type."
            }
        }
    }
}

<#
    .SYNOPSIS
    Converts a Fortune file to an array of Fortunes.
    .PARAMETER FortuneFile
    [System.String]
    Path of Fortune file.
    .PARAMETER Group
    [System.String]
    Group if Fortune file was found through Group/Config.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes.
#>
function Get-FortuneFromFile {
    param(
        [string]$FortuneFile,
        [string]$Group = $NULL
    )
    $fortunes_from_file = @()
    # Validation: Fortune filepath not valid
    if (-not (Test-Path($FortuneFile))) {
        return $fortunes_from_file
    }
    # Get each fortune file from path with wildcard.
    $FortuneFileItem = Get-ChildItem -Path $FortuneFile -Recurse -File
    foreach ($path in $FortuneFileItem) {
        $fortune_vmes = "Compiling fortunes from $path"
        Write-Verbose -Message $fortune_vmes
        $fortunes_from_file_buffer = (Get-Content -Path $path.FullName -Raw) -replace "`r`n", "`n" -split "`n%`n"
        $fortunes_from_file += foreach ($entry in $fortunes_from_file_buffer) {
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
    [System.String]
    Group of Fortune files.
    .PARAMETER ConfigObj
    [System.Collections.Hashtable]
    Object representation of Config file to pull Tag from.
    Previously used System.Object type to support multiple config formats and how they are imported to PowerShell.
    System.Object is the BaseType of Hashtable, OrderedDictionary, and PSCustomObject.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes.
#>
function Get-FortuneFromFileCollection {
    param(
        [string]$Tag,
        [System.Collections.Hashtable]$ConfigObj
    )
    $FilesInGroup = $ConfigObj.$Tag
    $fortunes_from_files = @()
    foreach ($path in $FilesInGroup) {
        $fortunes_from_files_buffer = Get-FortuneFromFile -FortuneFile $path -Group $Tag
        $fortunes_from_files += $fortunes_from_files_buffer
    }
    return $fortunes_from_files
}

<#
    .SYNOPSIS
    Calculate the time needed to read a fortune in seconds.
    .PARAMETER Length
    [System.Int32]
    Length of fortune.
    Should be a positive integer.
    See: https://proofwiki.org/wiki/Definition:Positive/Integer
    .PARAMETER Min
    [System.Int32]
    Minimum time to wait in seconds.
    Should be a positive integer.
    See: https://proofwiki.org/wiki/Definition:Positive/Integer
    .PARAMETER LPS
    [System.Int32]
    Letters Per Second.
    Should be a strictly positive integer.
    See: https://proofwiki.org/wiki/Definition:Strictly_Positive/Integer
    .OUTPUTS
    [System.Int32]
    Time to read the fortune in seconds.
#>
function Get-FortuneReadoutTime {
    param(
        [int]$Length = 0,
        [int]$Min = 6,
        [int]$LPS = 20
    )
    # Validation: Inputs are positive integers.
    if ($Length -lt 0) {
        $Length = 0
    }
    if ($Min -lt 0) {
        $Min = 0
    }
    if ($LPS -lt 1) {
        $LPS = 1
    }
    $sleep_calc_time = ($Length / $LPS)
    $sleep_time = if ($sleep_calc_time -gt $Min) { $sleep_calc_time } else { $Min }
    return $sleep_time
}

<#
    .SYNOPSIS
    Filter an array of Fortunes by character length.
    .PARAMETER Fortunes
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes to filter.
    .PARAMETER Long
    [System.Int32]
    Filter for fortunes that are longer than the given character length if present.
    .PARAMETER Short
    [System.Int32]
    Filter for fortunes that are shorter than the given character length if present.
    .PARAMETER Length
    [System.Int32]
    Filter for fortunes with the given character length if present.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
    Filtered array of Fortunes.
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
    $fortune_vmes = "$fortune_count_before to $fortune_count_after fortune(s) after length filter."
    Write-Verbose -Message $fortune_vmes

    return $Fortunes
}

<#
    .SYNOPSIS
    Filter an array of Fortunes by character matching.
    .PARAMETER Fortunes
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes to filter.
    .PARAMETER Pattern
    [System.String]
    Filter fortunes matching a given REGEX pattern.
    .PARAMETER Exclude
    [System.String]
    REGEX pattern to filter out from array.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
#>
function Select-FortunesByPattern {
    param(
        [PSCustomObject[]]$Fortunes,
        [string]$Pattern,
        [String]$Exclude
    )
    $fortune_count_before = $Fortunes.Count
    if ($Pattern) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune -match $Pattern
        }
    }
    if ($Exclude) {
        $Fortunes = $Fortunes | Where-Object {
            $_.Fortune -notmatch $Exclude
        }
    }
    $fortune_count_after = $Fortunes.Count
    $fortune_vmes = "$fortune_count_before to $fortune_count_after fortune(s) after pattern filter."
    Write-Verbose -Message $fortune_vmes

    return $fortunes
}

<#
    .SYNOPSIS
    Filter an array of Fortunes by Path.
    .PARAMETER Fortunes
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes to filter.
    .PARAMETER Path
    [System.String]
    Filter fortunes with a given Path value.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
#>
function Select-FortunesByPath {
    param(
        [PSCustomObject[]]$Fortunes,
        [string]$Path
    )
    if ($Path) {
        $Path = [regex]::escape($Path)
        $Fortunes = $Fortunes | Where-Object {
            $_.Path -eq $Path
        }
    }
    return $fortunes
}

<#
    .SYNOPSIS
    Output a random Fortune from an array.
    .PARAMETER Fortunes
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes.
    .PARAMETER RNG
    [System.Random]
    Random Number Generator object.
    Optimally should be used only in cases where a seeded Get-Random call is wanted.
    .EXAMPLE
    $fortune_output = Show-Fortune -Fortunes $fortunes
    .EXAMPLE
    $pseudo_rand = [System.Random]::new(1)
    $fortune_output = Show-Fortune -Fortunes $fortunes -RNG $pseudo_rand
    .OUTPUTS
    [System.String]
#>
function Show-Fortune {
    param(
        [PSCustomObject[]]$Fortunes,
        [System.Random]$RNG
    )
    # Validation: No fortunes for Get-Random (<= PowerShell v5.1)
    if ($Fortunes.Count -lt 1) {
        return
    }
    if ($RNG) {
        $final_fortune = $Fortunes[$RNG.Next($Fortunes.Count)]
    }
    else {
        $final_fortune = $Fortunes | Get-Random
    }
    Write-Output $final_fortune.Fortune
    return
}

<#
    .SYNOPSIS
    Output each Fortune in an array, delimited by "%".
    .PARAMETER Fortunes
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes.
    .EXAMPLE
    $fortunes_output = Show-PossibleFortuneList -Fortunes $fortunes
    .OUTPUTS
    [System.String[]]
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
    [System.Management.Automation.PSCustomObject[]]
    Array of Fortunes.
    .PARAMETER Equal
    [System.Boolean]
    Set the chance for each file to be equal.
    .OUTPUTS
    [System.Management.Automation.PSCustomObject[]]
#>
function Show-FortunePercentageByFile {
    param(
        [PSCustomObject[]]$Fortunes,
        [boolean]$Equal
    )
    $total_count = $Fortunes.Count
    $unique_paths = $Fortunes | Sort-Object -Unique -Property Path | Select-Object -Property Path
    # Calculate Percentage for each unique path
    $unique_paths | Add-Member -NotePropertyName Percentage -NotePropertyValue 0.0
    foreach ($path in $unique_paths) {
        $subsection = $Fortunes | Where-Object { $_.Path -eq $path.Path; }
        $path.Percentage = if ($Equal) { [double]((1 / $unique_paths.Count) * 100) } else { [double](($subsection.Count / $total_count) * 100) }
    }
    $unique_paths
    return
}

$isDotSourced = $MyInvocation.InvocationName -in '.', ''
if ($isDotSourced) {
    Write-Debug "Importing functions."
    exit 0
}

if ($Help) {
    # Recreate script in temp path without PSScriptInfo to have Get-Help work.
    $help_path = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "fortune-help.ps1")
    Get-Content -Path $PSCommandPath | Select-Object -Skip 5 | Set-Content -Path $help_path
    Get-Help -Name $help_path -Full
    exit 0
}

if ($Version) {
    $program_version = ([version]::new(1, 0, 6)).toString()
    Write-Output $program_version
    exit 0
}

# Parameter Logic
# - File has priority over Group and Config
if ($File -and $Group) {
    $Group = $NULL
    $Config = $NULL
}
# - Length has priority over Long and Short
if ($Length) {
    $Short = $NULL
    $Long = $NULL
}
# - Set Seed if present for Random Number Generator object
if ($PSBoundParameters.ContainsKey('Seed')) {
    $rng_object = [System.Random]::new($Seed)
    $fortune_vmes = "Fortune Seed: $Seed"
    Write-Verbose -Message $fortune_vmes
}
else {
    $rng_object = [System.Random]::new()
}

if ($File) {
    # Validation: File not a valid path
    if (-not (Test-Path -Path $File)) {
        Write-Error -Message "Fortune file not found or invalid path." -Category ReadError
        exit 1
    }
    $f = Get-FortuneFromFile -FortuneFile $File
}

if ($Group) {
    # Validation: File not a valid path
    if (-not (Test-Path -Path $Config)) {
        Write-Error -Message "Config file not found or invalid path." -Category ReadError
        exit 1
    }
    # Get data from config file.
    $config_file_ext = ((Get-Item -Path $Config).Extension).ToUpper()
    switch ($config_file_ext) {
        { $_ -in ".TOML" } {
            $cfg = ([FortuneConfig]::new($Config, "TOML")).Data
        }
        { $_ -in ".YAML", ".YML" } {
            $cfg = ([FortuneConfig]::new($Config, "YAML")).Data
        }
        { $_ -in ".JSON", ".JSONC" } {
            $cfg = ([FortuneConfig]::new($Config, "JSON")).Data
        }
        { $_ -in ".PSD1" } {
            $cfg = ([FortuneConfig]::new($Config, "PSD1")).Data
        }
        default {
            Write-Error -Message "Config file type not supported." -Category InvalidType
            exit 1
        }
    }
    $f = Get-FortuneFromFileCollection -Tag $Group -ConfigObj $cfg
}

$f = Select-FortunesByLength -Fortunes $f -Long $Long -Short $Short -Length $Length
$f = Select-FortunesByPattern -Fortunes $f -Pattern $Match

if ($Percentage) {
    Show-FortunePercentageByFile -Fortunes $f -Equal $Equidistribution
    exit 0
}

if ($Match) {
    Show-PossibleFortuneList -Fortunes $f
    $fortune_count = $f.Count
    $fortune_vmes = "$fortune_count fortune(s) matching pattern $Match"
    Write-Verbose -Message $fortune_vmes
    exit 0
}

$unique_paths = $f | Sort-Object -Unique -Property Path | Select-Object -Property Path
if (($unique_paths.Count -gt 1) -and ($Equidistribution)) {
    [string]$rand_file = $unique_paths[$rng_object.Next($unique_paths.Count)].Path
    $f = Select-FortunesByPath -Fortunes $f -Path $rand_file
}

$fortune_output = Show-Fortune -Fortunes $f -RNG $rng_object
Write-Output $fortune_output

if ($Wait) {
    $wait_time = Get-FortuneReadoutTime -Length $fortune_output.Length -Min 6
    $fortune_vmes = "Pausing for $wait_time second(s)"
    Write-Verbose -Message $fortune_vmes
    Start-Sleep -Seconds $wait_time
}

exit 0
