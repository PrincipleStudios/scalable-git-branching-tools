Describe 'processlog-framework' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/processlog-framework.psm1"
        Import-Module -Scope Local "$PSScriptRoot/processlog-framework.mocks.psm1"
    }

    BeforeEach {
        Register-ProcessLog
    }

    It 'can handle errors' {
        # This is an unmocked command. Git explicitly allows `.lock` branch names
        Invoke-ProcessLogs 'check-ref-format with invalid branch' {
            git check-ref-format --branch "test.lock"
        }
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'check-ref-format with invalid branch'
        $logs[0].logs[0] | Should -BeOfType System.Management.Automation.ErrorRecord
        $logs[0].logs[0].Exception.Message | Should -Be "fatal: 'test.lock' is not a valid branch name"
    }

    It 'can handle logs' {
        # This is an unmocked command that will always output a success when inside a git repository
        Invoke-ProcessLogs 'name-rev HEAD' {
            git name-rev HEAD
        }
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'name-rev HEAD'
        $logs[0].logs[0] | Should -BeOfType String
        $logs[0].logs[0] | Should -Not -BeNullOrEmpty
    }

    It 'can capture variables' {
        # This is an unmocked command that will always output a success when inside a git repository
        $nameRev = Invoke-ProcessLogs 'name-rev HEAD' {
            git name-rev HEAD
        } -allowSuccessOutput
        $logs = Get-ProcessLogs
        $logs[0].name | Should -Be 'name-rev HEAD'
        $logs[0].logs | Should -BeNullOrEmpty
        $nameRev | Should -Not -BeNullOrEmpty
    }

}
