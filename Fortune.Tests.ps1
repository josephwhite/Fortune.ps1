BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1') -Help | Out-Null;
    $script:foobar_fortune_content = @'
foo
%
bar
%
l0l -- lma0 even.
'@;
    $script:foobar_fortunes_buffer = $foobar_fortune_content -replace "`r`n", "`n" -split "`n%`n"
    $script:foobar_fortunes = Foreach ($entry in $foobar_fortunes_buffer) {
        [PSCustomObject] @{
            Fortune = $entry
            Path    = "C:\foo\fortunes.txt"
        };
    }
}

Describe 'Get-FortuneFromFile' {
    It 'Gets Fortunes from file path' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $f = Get-FortuneFromFile -FortuneFile $path;
        $f.Count | Should -Be 432
    }
    It 'Gets Fortunes from file paths (wildcard)' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "*")
        $f = Get-FortuneFromFile -FortuneFile $path;
        $f.Count | Should -Be 432
    }
    It 'Remembers the file path' {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $f = Get-FortuneFromFile -FortuneFile $path;
        foreach ($fortune in $f ) {
            $Fortune.Path | Should -Be $path;
        }
    }
}

Describe 'Get-FortuneFromFileCollection' {
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
'@ -f $path_wild, $path_wtxt;
            $cfg = $content | ConvertFrom-Toml;
        }
        It 'Parses TOML with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
            }
        }
        It 'Parses TOML with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
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
            $script:cfg = ConvertFrom-Json $content
        }
        It 'Parses JSON with default group' {
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
            }
        }
        It 'Parses JSON with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
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
            $f = Get-FortuneFromFileCollection -Tag "default" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
            }
        }
        It 'Parses PSD1 with custom group' {
            $f = Get-FortuneFromFileCollection -Tag "example" -ConfigObj $cfg;
            foreach ($fortune in $f ) {
                $Fortune.Path | Should -Be $path_wtxt;
            }
        }
    }
}

Describe 'Select-FortunesByLength' {
    BeforeEach {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path;
    }
    It 'Filters Fortunes >= x (Longer)' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20;
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeGreaterOrEqual 20;
        }
    }
    It 'Filters Fortunes <= x (Shorter)' {
        $f = Select-FortunesByLength -Fortunes $f -Short 100;
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeLessOrEqual 100;
        }
    }
    It 'Filters Fortunes >= x and <= y (Between)' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20 -Short 100;
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -BeLessOrEqual 100;
            $Fortune.Length | Should -BeGreaterOrEqual 20;
        }
    }
    It 'Filters Fortunes = x (Exact)' {
        $f = Select-FortunesByLength -Fortunes $f -Length 50;
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -Be 50;
        }
    }
    It 'Prioritizes (Exact) when present' {
        $f = Select-FortunesByLength -Fortunes $f -Long 20 -Short 100 -Length 50;
        foreach ($fortune in $f.Fortune) {
            $Fortune.Length | Should -Be 50;
        }
    }
}

Describe 'Select-FortunesByPattern' {
    BeforeEach {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path;
    }
    It 'Matches keywords' {
        $f = Select-FortunesByPattern -Fortunes $f -Pattern "You"
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match "You";
        }
    }
    It 'Matches regex' {
        $f = Select-FortunesByPattern -Fortunes $f -Pattern [0-9]
        foreach ($fortune in $f.Fortune) {
            $Fortune | Should -Match [0-9];
        }
    }
}

Describe 'Show-Fortune' {
    BeforeEach {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path;
    }
    It 'Outputs random Fortune' {
        $fortune = Show-Fortune -Fortunes $f;
        $fortune | Should -Not -BeNullOrEmpty
    }
    It 'Outputs nothing with no input' {
        $fortune = Show-Fortune;
        $fortune | Should -BeNullOrEmpty
    }
}
Describe 'Show-PossibleFortuneList' {
    BeforeEach {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path;
    }
    It 'Outputs fortunes, delimited by %' {
        $fortune = Show-PossibleFortuneList -Fortunes $f;
        $fortune | Should -Contain "%"
    }
    It 'Outputs nothing with no input' {
        $fortune = Show-PossibleFortuneList;
        $fortune | Should -BeNullOrEmpty
    }
}

Describe 'Show-FortunePercentageByFile' {
    BeforeEach {
        $path = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
        $script:f = Get-FortuneFromFile -FortuneFile $path;
    }
    It 'Knows file paths' {
        $percents = Show-FortunePercentageByFile -Fortunes $f;
        $percents.Path | Should -Be $path
        $percents = Show-FortunePercentageByFile -Fortunes $foobar_fortunes
        $percents.Path | Should -Be "C:\foo\fortunes.txt"
    }
    It 'Calculates percentage' {
        $percents = Show-FortunePercentageByFile -Fortunes $f;
        $percents.Percentage | Should -Be 100
    }
    It 'Outputs nothing with no input' {
        $percents = Show-FortunePercentageByFile
        $percents | Should -BeNullOrEmpty
    }
}

Describe 'Fortune.ps1' {
    BeforeEach {
        $script:script_path = $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    }
    Context 'Util' {
        It 'Outputs Get-Help' {
            $script_gethelp_output = (Get-Help -Name $script_path 2>&1 | Out-String) + "
  Run the following command for full documentation.
    Get-Help $script_path -Full


";
            $script_help_output = & $script_path -Help 2>&1 | Out-String;
            $script_help_output | Should -Be $script_gethelp_output
        }
    }
    Context 'Logic' {
        It 'Gives priority to Length over Short and Long' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            $script_output = & $script_path -File $path_wtxt -Long 20 -Short 100 -Length 50;
            $script_output.Length | Should -Be 50;
        }
    }
    Context 'Exit' {
        It 'Returns Exit Code 1 for invalid path (File parameter)' {
            & $script_path -File "``" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 1;
        }
        It 'Returns Exit Code 1 for invalid path (Config parameter)' {
            & $script_path -Config "``" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 1;
        }
        It 'Returns Exit Code 0 for running successfully (File parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0;
        }
        It 'Returns Exit Code 0 for running successfully (File+Match parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt -Match "You" 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0;
        }
        It 'Returns Exit Code 0 for running successfully (File+Percentage parameter)' {
            $path_wtxt = [System.IO.Path]::Combine($PSScriptRoot, "fortunes", "example_fortunes.txt")
            & $script_path -File $path_wtxt -Percentage 2>&1
            [int]$lec = $LASTEXITCODE
            $lec | Should -Be 0;
        }
    }
}
