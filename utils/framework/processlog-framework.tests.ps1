Describe 'processlog-framework' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/processlog-framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/processlog-framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../testing.psm1"
    }

    BeforeEach {
        Register-ProcessLog
    }

    It 'can handle errors as "exceptions"' {
        Invoke-ProcessLogs 'sample error' {
            Write-Error "full error message"
        }
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'sample error'
        $logs[0].logs[0] | Should -BeOfType System.Management.Automation.ErrorRecord
        $logs[0].logs[0].Exception.Message | Should -Be "full error message"
        $logs.Count | Should -Be 1
    }

    It 'can handle logs' {
        Invoke-ProcessLogs 'script with output' {
            Write-Output "sample output"
        }
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'script with output'
        $logs[0].logs[0] | Should -BeOfType String
        $logs[0].logs[0] | Should -Be "sample output"
        $logs.Count | Should -Be 1
        $logs[0].logs.Count | Should -Be 1
    }

    It 'can capture string output' {
        $nameRev = Invoke-ProcessLogs 'script with output' {
            Write-Output "sample output"
        } -allowSuccessOutput
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'script with output'
        $logs[0].logs | Should -BeNullOrEmpty
        $nameRev | Should -Be "sample output"
        $logs.Count | Should -Be 1
    }

    It 'cannot capture object outputs; it cannot tell the difference between streams' {
        $output = Invoke-ProcessLogs 'object' {
            @{ foo = 'bar' }
        } -allowSuccessOutput
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'object'
        $logs[0].logs | Assert-ShouldBeObject @{ foo = 'bar' }
        $output | Should -BeNullOrEmpty
        $logs.Count | Should -Be 1
        $logs[0].logs.Count | Should -Be 1
    }
    
    It 'preserves error codes' {
        $output = Invoke-ProcessLogs 'error-code test' {
            $global:LASTEXITCODE = 15
        } -allowSuccessOutput
        $global:LASTEXITCODE | Should -Be 15
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'error-code test'
        $logs[0].logs | Should -BeNullOrEmpty
        $output | Should -BeNullOrEmpty
        $logs.Count | Should -Be 1
    }
    
    # Skipping because the "Working on 'sleep'..." cannot be mocked
    It 'can run for a while without logs' -Skip {
        Mock -ModuleName 'processlog-framework' -CommandName 'Get-IsQuiet' { return $false }
        $output = Invoke-ProcessLogs 'sleep' {
            Start-Sleep -Milliseconds 100
        } -beginThreshold 0.05

        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'sleep'
        $logs[0].logs | Should -BeNullOrEmpty
        $output | Should -BeNullOrEmpty
        $logs.Count | Should -Be 1

        # Should -ModuleName 'processlog-framework' -Invoke -CommandName 'Write-Host' -ParameterFilter { $Object.StartsWith("Working on 'sleep'...") } -Times 1
        Should -ModuleName 'processlog-framework' -Invoke -CommandName 'Write-Host' -ParameterFilter { $Object.StartsWith("End 'sleep'.") } -Times 1
    }
}
