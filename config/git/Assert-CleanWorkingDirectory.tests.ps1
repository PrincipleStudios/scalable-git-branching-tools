BeforeAll {
    . $PSScriptRoot/Assert-CleanWorkingDirectory.ps1
}

Describe 'Assert-CleanWorkingDirectory' {
    It 'throws if exit code is non-zero' {
        Mock git {
            $Global:LASTEXITCODE = 1
        } -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' }
            
        { Assert-CleanWorkingDirectory } | Should -Throw
    }
    It 'throws if non-ignored files exist' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' } {
            $Global:LASTEXITCODE = 0
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'clean -n' } {
            Write-Output 'Would remove temp.txt'
        }
            
        { Assert-CleanWorkingDirectory } | Should -Throw
    }
    It 'does not throw if exit code is 0 and no non-ignored files exist' {
        Mock git -ParameterFilter { ($args -join ' ') -eq 'diff --stat --exit-code --quiet' } {
            $Global:LASTEXITCODE = 0
        }
        Mock git -ParameterFilter { ($args -join ' ') -eq 'clean -n' } {
        }
            
        Assert-CleanWorkingDirectory
    }
}
