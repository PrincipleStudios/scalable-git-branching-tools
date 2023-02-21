BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-Configuration.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-CurrentBranch.mocks.psm1"
    Import-Module -Scope Local "$PSScriptRoot/config/git/Get-GitFile.mocks.psm1"
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    # Mock -CommandName Write-Host {}
}

Describe 'git-show-upstream' {
    It 'shows the results of an upstream branch' {
        Initialize-ToolConfiguration
        Initialize-GitFile 'origin/_upstream' 'feature/FOO-123' @("main", "infra/add-services")

        $result = & ./git-show-upstream.ps1 -branchName 'feature/FOO-123'
        $result | Should -Be @('origin/main', 'origin/infra/add-services')
    }

    It 'shows the results of the current branch if none is specified' {
        Initialize-ToolConfiguration
        Initialize-CurrentBranch 'feature/FOO-123'

        Initialize-GitFile 'origin/_upstream' 'feature/FOO-123' @("main", "infra/add-services")

        $result = & ./git-show-upstream.ps1
        $result | Should -Be @('origin/main', 'origin/infra/add-services')
    }

    It 'shows recursive the results of the current branch if none is specified' {
        Initialize-ToolConfiguration
        Initialize-CurrentBranch 'feature/FOO-123'

        Initialize-GitFile 'origin/_upstream' 'feature/FOO-123' $("main", "infra/add-services")
        Initialize-GitFile 'origin/_upstream' 'main' $()
        Initialize-GitFile 'origin/_upstream' 'infra/add-services' $('infra/build-infrastructure')
        Initialize-GitFile 'origin/_upstream' 'infra/build-infrastructure' $()

        $result = & ./git-show-upstream.ps1 -recurse
        $result | Should -Be @('origin/main', 'origin/infra/add-services', 'origin/infra/build-infrastructure')
    }
}
