Describe 'local action "simplify-upstream"' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../query-state.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../../git.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../Invoke-LocalAction.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Register-LocalActionSimplifyUpstreamBranches.mocks.psm1"
        . "$PSScriptRoot/../../testing.ps1"
    }
    
    BeforeEach {
        $fw = Register-Framework -throwInsteadOfExit
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $output = $fw.diagnostics
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Justification='This is put in scope and used in the tests below')]
        $diag = New-Diagnostics
    }

    It 'allows fallback to the default service line' {
        Initialize-ToolConfiguration -defaultServiceLine 'line/1.0'

        $result = Invoke-LocalAction @{
            type = 'simplify-upstream'
            parameters = @{
                upstreamBranches = @()
            }
        } -diagnostics $diag
        try { Assert-Diagnostics $diag } catch { }
        $output | Should -BeNullOrEmpty
        Should -ActualValue $result -Be @('line/1.0')
    }

    It 'allows mocked simplification' {
        Initialize-LocalActionSimplifyUpstreamBranchesSuccess -from @('foo', 'bar') -to @('foo')

        $result = Invoke-LocalAction @{
            type = 'simplify-upstream'
            parameters = @{
                upstreamBranches = @('foo', 'bar')
            }
        } -diagnostics $diag
        try { Assert-Diagnostics $diag } catch { }
        $output | Should -BeNullOrEmpty
        Should -ActualValue $result -Be @('foo')
    }
}
