BeforeAll {
    . $PSScriptRoot/Get-ParentTicketsFromBranchName.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'Get-ParentTicketsFromBranchName' {
    It 'gets parent tickets for feature branches' {
        Get-ParentTicketsFromBranchName 'feature/PS-100_PS-101-some-work' | Should -Be @('PS-100')
    }
    It 'gets parent tickets for integration branches' {
        Get-ParentTicketsFromBranchName 'integrate/PS-100_XYZ-150' | Should -Be @('PS-100', 'XYZ-150')
    }
}
