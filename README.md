# Fortune.ps1

A PowerShell implementation of the [unix `fortune` program](https://www.wikipedia.org/wiki/Fortune_(Unix)). This project aims to implement many features from the original program with new ideas for more flexibility. Flags `-a` and `-o` from the original have been replaced by an approach using arrays of filepaths from config files. This allows not only more specific groupings to seperate fortune files, but also allows fortune files to be independent from a single directory.

### Teapot Status
[![PSScriptAnalyzer](https://github.com/josephwhite/Fortune.ps1/actions/workflows/powershell.yml/badge.svg)](https://github.com/josephwhite/Fortune.ps1/actions/workflows/powershell.yml)
![Static Badge](https://img.shields.io/badge/LICENSE-AGPL_3.0_only-blue)

## Features

- Optional config based quote pooling.
	-  Directory independent.
	-  Arrays of filepaths.
	-  Supports JSON, PSD1, TOML, and YAML.
- Length and Pattern parameters.
- Compatible with PowerShell v5.1+.
- Comment-based help for `Get-Help` parsing.

Example of config.toml
```toml
default = [
	'C:\foobar\fortunes\*',
]

TV = [
	'C:\foobar\fortunes\xfiles.txt',
	'C:\bazbar\breakingbad.txt',
	'D:\path\simpsons.txt',
]
```

## Parameters

Please read the `Get-Help` for example calls and in-depth parameter descriptions.
| Parameter        | Alias   | Action                                                         |
|:-----------------|:--------|:---------------------------------------------------------------|
| PRIMARY|
| File [path]      | f       | Filepath of Fortune file(s) to pool quotes from.|
| Config [path]    | c       | Config filepath. Should contain groupings of fortune filepaths.<br> Default is current directory + "\fortune_config.psd1".|
| Group [foo]      | g       | Group to pool from within config file.<br> Default is "default".|
| SECONDARY|
| Long [#]         | l       | Only use quotes longer than the length specified.|
| Short [#]        | s       | Only use quotes shorter than the length specified.|
| Length [#]       | n/ls    | Only use quotes that are exactly the length given.|
| Match [pattern]  | m/regex | Print all quotes matching the regex pattern given.|
| Percentage       | p       | Print filepaths of Fortune files and percentages.|
| Seed [#]         |         | Sets seed for randomization.|
| Equidistribution | e       | Distribute equal probability among the selected Fortune files.|
| Wait             | w       | Waits before exiting after printing single fortune.|
| UTILITY|
| Version          | v       | Print version info and exit.|
| Help             | h       | Print help info and exit.|

## Dependencies
- Usage of a TOML config file requires [PSToml](https://github.com/jborean93/PSToml) and PowerShell v5.1+.
- Usage of a YAML config file requires [powershell-yaml](https://github.com/cloudbase/powershell-yaml).
