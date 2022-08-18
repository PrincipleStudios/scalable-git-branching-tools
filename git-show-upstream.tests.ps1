BeforeAll {
    Mock git {
        throw "Unmocked git command: $args"
    }

    # User-interface commands are a bit noisy; TODO: add quiet option and test it by making this throw
    Mock -CommandName Write-Host {}
}

Describe 'git-show-upstream' {
    It 'shows the results of an upstream branch' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = $nil } }
        
        Mock git {
            "main"
            "infra/add-services"
        } -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-123'}

        $result = & ./git-show-upstream.ps1 -branchName 'feature/FOO-123'
        $result | Should -Be @('origin/main', 'origin/infra/add-services')
    }
    
    It 'shows the results of the current branch if none is specified' {
        . $PSScriptRoot/config/git/Get-Configuration.ps1
        Mock -CommandName Get-Configuration { return @{ remote = 'origin'; upstreamBranch = '_upstream'; defaultServiceLine = $nil } }
        
        Mock git -ParameterFilter {($args -join ' ') -eq 'branch --show-current'} { 'feature/FOO-123' }

        Mock git -ParameterFilter {($args -join ' ') -eq 'cat-file -p origin/_upstream:feature/FOO-123'} {
            "main"
            "infra/add-services"
        }

        $result = & ./git-show-upstream.ps1
        $result | Should -Be @('origin/main', 'origin/infra/add-services')
    }
}
