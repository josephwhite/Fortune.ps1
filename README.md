# Fortune.ps1

A PowerShell implementation of the [unix `fortune` program](https://www.wikipedia.org/wiki/Fortune_(Unix)). This project aims to implement many features from the original C program with new ideas for more flexibility. Flags `-a` and `-o` from the original have been replaced by an approach using arrays of filepaths from config files. This allows not only more specific groupings to seperate fortune files, but also allows fortune files to be independent from a single directory.

## Features

- Optional config based quote pooling.
	-  Directory independent.
	-  Arrays of filepaths.
	-  Supports JSON, PSD1, and TOML.
- Length and Pattern parameters. 
- Comment-based help for `Get-Help` parsing.

Usage of a TOML config file requires [PSTOML](https://github.com/jborean93/PSToml) and PowerShell v5.1+.

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
| Flag         | Action                                                          |
|:-------------|:----------------------------------------------------------------|
| -f [path]    | Filepath of Fortune file(s) to pool quotes from.                |
| -c [path]    | Config filepath. Should contain groupings of fortune filepaths. Default is current directory + "\fortune_config.psd1" |
| -g [foo]     | Group to pool from within config file. Default is "default".    |
|              |                                                                 |
| -l [#]       | Only use quotes than the length specified.                      |
| -s [#]       | Only use quotes shorter than the length specified.              |
| -n [#]       | Only use quotes that are exactly the length given.              |
| -m [pattern] | Print all quotes matching the regex pattern given.              |


## TODO

- Some type of CI/CD.
	- Install Modules.
	- Test Cases.
	- Windows and Linux Support.
- Add YAML config support when PowerShell officially supports YAML parsers.