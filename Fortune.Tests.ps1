BeforeAll {
    # . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Help | Out-Null
    $script:foobar_fortune_content = @'
foo
%
bar
%
l0l -- lma0 even.
'@
    $script:foobar_fortunes_buffer = $foobar_fortune_content -replace "`r`n", "`n" -split "`n%`n"
    $script:foobar_fortunes = foreach ($entry in $foobar_fortunes_buffer) {
        [PSCustomObject] @{
            Fortune = $entry
            Path    = "C:\foo\fortunes.txt"
            Group   = "FOO"
        }
    }
}

Describe 'Config Class' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
    }
    It 'Creates a Hashtable (TOML)' {
        $path_toml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.toml")
        $cfg_buffer = [FortuneConfig]::new($path_toml, "TOML")
        $cfg = $cfg_buffer.Data
        $cfg | Should -BeOfType "System.Collections.Hashtable"
    }
    It 'Creates a Hashtable (YAML)' {
        $path_yaml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.yml")
        $cfg_buffer = [FortuneConfig]::new($path_yaml, "YAML")
        $cfg = $cfg_buffer.Data
        $cfg | Should -BeOfType "System.Collections.Hashtable"
    }
    It 'Creates a Hashtable (JSON)' {
        $path_json = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.json")
        $cfg_buffer = [FortuneConfig]::new($path_json, "JSON")
        $cfg = $cfg_buffer.Data
        $cfg | Should -BeOfType "System.Collections.Hashtable"
    }
    It 'Creates a Hashtable (PSD1)' {
        $path_psd1 = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.psd1")
        $cfg_buffer = [FortuneConfig]::new($path_psd1, "PSD1")
        $cfg = $cfg_buffer.Data
        $cfg | Should -BeOfType "System.Collections.Hashtable"
    }
    It 'Needs a valid type' {
        $cfg_buffer = [FortuneConfig]::new([System.IO.Path]::Combine($PSScriptRoot, "example_config.toml"), "TXT") 2>&1
        $cfg = $cfg_buffer.Data
        $cfg | Should -BeNullOrEmpty
    }
}

Describe 'Get-FortuneReadoutTime' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
    }
    It 'Uses Length' {
        $wait_time = Get-FortuneReadoutTime -Length 200
        $wait_time | Should -Be 10
    }
    It 'Deafults to the minimum if length is too short' {
        $wait_time = Get-FortuneReadoutTime -Length 1 -Min 6
        $wait_time | Should -Be 6
    }
    It 'Defaults to 0 if inputs are negative' {
        $wait_time = Get-FortuneReadoutTime -Length -10 -Min -9 -LPS -8
        $wait_time | Should -Be 0
    }
}

Describe 'Get-FortuneFromFile' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
    }
    It 'Gets Fortunes from file path' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $f = Get-FortuneFromFile -FortuneFile $path
        $f.Count | Should -Be 432
    }
    It 'Gets Fortunes from file paths (wildcard)' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
        $f = Get-FortuneFromFile -FortuneFile $path
        $f.Count | Should -Be 432
    }
    It 'Remembers the file path' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $f = Get-FortuneFromFile -FortuneFile $path
        foreach ($fortune in $f ) {
            $Fortune.Path | Should -Be $path
        }
    }
    It 'Remembers the Group' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $f = Get-FortuneFromFile -FortuneFile $path
        foreach ($fortune in $f ) {
            $Fortune.Group | Should -BeNullOrEmpty
        }
        $f = Get-FortuneFromFile -FortuneFile $path -Group "default"
        foreach ($fortune in $f ) {
            $Fortune.Group | Should -Be "default"
        }
    }
}

Describe 'Get-FortuneFromFileCollection' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
    }
    Context "TOML" {
        BeforeEach {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $path_wild = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
            $content = @'
default = [
    '{0}',
]
example = [
    '{1}'
]
'@ -f $path_wild, $path_wtxt
            $script:cfg = $content | ConvertFrom-Toml
        }
        It 'Parses TOML with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
        It 'Parses TOML with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
    }
    Context "YAML" {
        BeforeEach {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $path_wild = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
            $content = @'
default:
    - '{0}'
example:
    - '{1}'
'@ -f $path_wild, $path_wtxt
            $script:cfg = $content | ConvertFrom-Yaml
        }
        It 'Parses YAML with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
        It 'Parses YAML with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
    }
    Context "JSON" {
        BeforeEach {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $path_wild = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
            $content = @{
                default = @(
                    $path_wild
                )
                example = @(
                    $path_wtxt
                )
            }
            $content = $content | ConvertTo-Json -Depth 100
            $cfg_buffer = ConvertFrom-Json $content
            $cfg = @{}
            $cfg_buffer | Get-Member -MemberType Properties | ForEach-Object {
                $cfg.Add($_.Name, $cfg_buffer.($_.Name))
            }
        }
        It 'Parses JSON with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
        It 'Parses JSON with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
    }
    Context "PSD1" {
        BeforeEach {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $path_wild = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
            $script:cfg = @{
                default = @(
                    $path_wild
                )
                example = @(
                    $path_wtxt
                )
            }
        }
        It 'Parses PSD1 with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
        It 'Parses PSD1 with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt
            }
        }
    }
}

Describe 'Select-FortunesByLength' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Filters Fortunes >= x (Longer)' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeGreaterOrEqual 20
        }
    }
    It 'Filters Fortunes <= x (Shorter)' {
        $f = Select-FortunesByLength -Fortunes $f -Short 100
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeLessOrEqual 100
        }
    }
    It 'Filters Fortunes >= x and <= y (Between)' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20 -Short 100
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeLessOrEqual 100
            $Fortune.Length | Should -BeGreaterOrEqual 20
        }
    }
    It 'Filters Fortunes = x (Exact)' {
        $f = Select-FortunesByLength -Fortunes $f -Length 50
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -Be 50
        }
    }
    It 'Prioritizes (Exact) when present' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20 -Short 100 -Length 50
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -Be 50
        }
    }
    It 'Filters everything out if Short < Long' {
        $fb = $NULL
        $fb = Select-FortunesByLength -Fortunes $f -Long 100 -Short 20
        $fb | Should -BeNullOrEmpty
        $fb = $NULL
        $fb = Select-FortunesByLength -Fortunes $f -Long 100 -Short 20 -Length 50
        $fb | Should -BeNullOrEmpty
    }
}

Describe 'Select-FortunesByPattern' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Matches keywords' {
        $f = Select-FortunesByPattern -Fortunes $f -Pattern "You"
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match "You"
        }
    }
    It 'Matches regex' {
        $f = Select-FortunesByPattern -Fortunes $f -Pattern [0-9]
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match [0-9]
        }
    }
    It 'Excludes patterns if specified' {
        $f = Select-FortunesByPattern -Fortunes $f -Pattern "You" -Exclude "will"
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match "You"
            $Fortune | Should -Not -Match "will"
        }
    }
}

Describe 'Select-FortunesByPath' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Filters with Path property' {
        $junk = Get-FortuneFromFile -FortuneFile $path
        foreach ($j in $junk) { $j.Path = "LOL" }
        $f += $junk
        $f = Select-FortunesByPath -Fortunes $f -Path $path
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match $path
        }
    }
}


Describe 'Show-Fortune' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Outputs random Fortune' {
        $fortune = Show-Fortune -Fortunes $f
        $fortune | Should -Not -BeNullOrEmpty
    }
    It 'Outputs different fortunes based on seed' {
        $rng_object1 = [System.Random]::new(1000)
        $fortune1 = Show-Fortune -Fortunes $f -RNG $rng_object1
        $fortune2 = Show-Fortune -Fortunes $f -RNG $rng_object1
        $rng_object2 = [System.Random]::new(1000)
        $fortune3 = Show-Fortune -Fortunes $f -RNG $rng_object2
        $fortune1 | Should -Be -Not $fortune2
        $fortune1 | Should -Be $fortune3
    }
    It 'Outputs nothing with no input' {
        $fortune = Show-Fortune
        $fortune | Should -BeNullOrEmpty
    }
}
Describe 'Show-PossibleFortuneList' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Outputs fortunes, delimited by %' {
        $fortune = Show-PossibleFortuneList -Fortunes $f
        $fortune | Should -Contain "%"
    }
    It 'Outputs nothing with no input' {
        $fortune = Show-PossibleFortuneList
        $fortune | Should -BeNullOrEmpty
    }
}

Describe 'Show-FortunePercentageByFile' -Tag "WindowsOnly", "MacosOnly" {
    BeforeEach {
        . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Version | Out-Null
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path
    }
    It 'Knows file paths' {
        $percents = Show-FortunePercentageByFile -Fortunes $f
        $percents.Path | Should -Be $path
        $percents = Show-FortunePercentageByFile -Fortunes $foobar_fortunes
        $percents.Path | Should -Be "C:\foo\fortunes.txt"
    }
    It 'Calculates percentage' {
        $percents = Show-FortunePercentageByFile -Fortunes $f
        $percents.Percentage | Should -Be 100
    }
    It 'Outputs nothing with no input' {
        $percents = Show-FortunePercentageByFile
        $percents | Should -BeNullOrEmpty
    }
}

Describe 'Fortune.ps1' -Tag "WindowsOnly", "MacosOnly", "LinuxOnly" {
    BeforeEach {
        $script:script_path = $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    }
    Context 'Util' {
        It 'Outputs Version' {
            $psfi = Get-PSScriptFileInfo -Path $script_path
            [string]$script_version_meta = $psfi.ScriptMetadataComment.Version.OriginalVersion
            [string]$script_version_param_output = & $script_path -Version 2>&1
            $script_version_param_output | Should -Be $script_version_meta
        }
        It 'Outputs Get-Help' {
            $help_path = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "fortune-help.ps1")
            Get-Content -Path $script_path | Select-Object -Skip 5 | Set-Content -Path $help_path
            $script_gethelp_output = (Get-Help -Name $help_path 2>&1 | Out-String)
            $script_help_param_output = & $script_path -Help 2>&1 | Out-String
            $script_help_param_output | Should -Be $script_gethelp_output
        }
        It 'Outputs Verbose Messaging' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            [string[]]$script_output = & $script_path -File $path_wtxt -Match "LOL" -Verbose 4>&1
            [string]$script_output[3] | Should -Be "0 fortune(s) matching pattern LOL"
        }
    }
    Context 'Logic' {
        It 'Gives priority to Length over Short and Long' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $script_output = & $script_path -File $path_wtxt -Long 20 -Short 100 -Length 50
            $script_output.Length | Should -Be 50
        }
        It 'Does not overwrite a Get-Random seed in session' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $rng_seed = Get-Random -Minimum 0 -Maximum 1000
            $script_output1 = & $script_path -File $path_wtxt -Seed $rng_seed
            $get_random1 = Get-Random
            $script_output2 = & $script_path -File $path_wtxt -Seed $rng_seed
            $get_random2 = Get-Random
            $script_output1 | Should -Be $script_output2
            $get_random1 | Should -Not -Be $get_random2
        }
    }
    Context 'Exit' {
        # Exit 0
        It 'Returns Exit Code 0 for running with Help parameter' {
            & $script_path -Help 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running with Version parameter' {
            & $script_path -Version 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (File parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (File+Match parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt -Match "You" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (File+Percentage parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (Config parameter)' {
            $path_toml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.toml")
            & $script_path -Config $path_toml 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_json = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.json")
            & $script_path -Config $path_json 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_psd1 = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.psd1")
            & $script_path -Config $path_psd1 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (Config+Group parameter)' {
            $path_toml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.toml")
            & $script_path -Config $path_toml -Group "TV" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_yaml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.yml")
            & $script_path -Config $path_yaml -Group "TV" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_json = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.json")
            & $script_path -Config $path_json -Group "TV" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_psd1 = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.psd1")
            & $script_path -Config $path_psd1 -Group "TV" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (Config+Match parameter)' {
            $path_toml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.toml")
            & $script_path -Config $path_toml -Match "LOL" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_yaml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.yml")
            & $script_path -Config $path_yaml -Match "LOL" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_json = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.json")
            & $script_path -Config $path_json -Match "LOL" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_psd1 = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.psd1")
            & $script_path -Config $path_psd1 -Match "LOL" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running successfully (Config+Percentage parameter)' {
            $path_toml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.toml")
            & $script_path -Config $path_toml -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_yaml = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.yml")
            & $script_path -Config $path_yaml -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_json = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.json")
            & $script_path -Config $path_json -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            $path_psd1 = [System.IO.Path]::Combine($PSScriptRoot, "configs", "example_config.psd1")
            & $script_path -Config $path_psd1 -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        It 'Returns Exit Code 0 for running with empty File, Group, and Config parameters' {
            & $script_path -File "" -Group "" -Config "" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
            & $script_path -File "" -Group "" -Config "" -Length 20 -Match "Y" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0
        }
        # Exit 1
        It 'Returns Exit Code 1 for invalid path (File parameter)' {
            & $script_path -File "``" -ErrorVariable ev -ErrorAction SilentlyContinue
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 1
        }
        It 'Returns Exit Code 1 for invalid path (Config parameter)' {
            & $script_path -Config "``" -ErrorVariable ev -ErrorAction SilentlyContinue
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 1
        }
        It 'Returns Exit Code 1 for invalid Config file type' {
            $ex_fortunes_path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -Config $ex_fortunes_path -ErrorVariable ev -ErrorAction SilentlyContinue
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 1
        }
    }
}
