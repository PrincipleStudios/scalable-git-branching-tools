BeforeAll {
    . $PSScriptRoot/To-BranchInfo.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'To-BranchInfo' {
    It 'returns nil for malformed branches' {
        To-BranchInfo 'master' | Should -Be $nil
    }
    
    It 'identifies main' {
        To-BranchInfo 'main' | Should-BeObject @{ type = 'service-line' }
    }
    
    It 'identifies feature branches' {
        To-BranchInfo 'feature/PS-123' | Should-BeObject @{ type = 'feature'; ticket='PS-123' }
        To-BranchInfo 'feature/PS-123-with-comment' | Should-BeObject @{ type = 'feature'; ticket='PS-123'; comment='with-comment' }
        To-BranchInfo 'feature/PS-123_PS-124' | Should-BeObject @{ type = 'feature'; ticket='PS-124'; parents=@('PS-123') }
        To-BranchInfo 'feature/PS-123_PS-124-another-comment' | Should-BeObject @{ type = 'feature'; ticket='PS-124'; parents=@('PS-123'); comment='another-comment' }
        To-BranchInfo 'feature/PS-123_PS-124_PS-125' | Should-BeObject @{ type = 'feature'; ticket='PS-125'; parents=@('PS-123','PS-124') }
        To-BranchInfo 'feature/PS-123_PS-124_PS-125-longish' | Should-BeObject @{ type = 'feature'; ticket='PS-125'; parents=@('PS-123','PS-124'); comment='longish' }
    }

    It 'identifies bugfix branches' {
        To-BranchInfo 'bugfix/PS-123' | Should-BeObject @{ type = 'bugfix'; ticket='PS-123' }
        To-BranchInfo 'bugfix/PS-123-with-comment' | Should-BeObject @{ type = 'bugfix'; ticket='PS-123'; comment='with-comment' }
        To-BranchInfo 'bugfix/PS-123_PS-124' | Should-BeObject @{ type = 'bugfix'; ticket='PS-124'; parents=@('PS-123') }
        To-BranchInfo 'bugfix/PS-123_PS-124-another-comment' | Should-BeObject @{ type = 'bugfix'; ticket='PS-124'; parents=@('PS-123'); comment='another-comment' }
        To-BranchInfo 'bugfix/PS-123_PS-124_PS-125' | Should-BeObject @{ type = 'bugfix'; ticket='PS-125'; parents=@('PS-123','PS-124') }
        To-BranchInfo 'bugfix/PS-123_PS-124_PS-125-longish' | Should-BeObject @{ type = 'bugfix'; ticket='PS-125'; parents=@('PS-123','PS-124'); comment='longish' }
    }

    It 'identifies rc branches' {
        To-BranchInfo 'rc/2022-07-14' | Should-BeObject @{ type = 'rc'; comment='2022-07-14' }
        To-BranchInfo 'rc/2022-07-14.1' | Should-BeObject @{ type = 'rc'; comment='2022-07-14.1' }
    }

    It 'identifies integration branches' {
        To-BranchInfo 'integrate/ABC-1234_ABC-1235' | Should-BeObject @{ type = 'integration'; tickets=@('ABC-1234','ABC-1235') }
        To-BranchInfo 'integrate/ABC-1234_ABC-1235_XYZ-78' | Should-BeObject @{ type = 'integration'; tickets=@('ABC-1234','ABC-1235','XYZ-78') }
    }
    
    It 'identifies infrastructure branches' {
        To-BranchInfo 'infra/button-component' | Should-BeObject @{ type = 'infrastructure'; comment='button-component' }
        To-BranchInfo 'infra/refactor-plugin-api' | Should-BeObject @{ type = 'infrastructure'; comment='refactor-plugin-api' }
        To-BranchInfo 'infra/update-typescript' | Should-BeObject @{ type = 'infrastructure'; comment='update-typescript' }
    }

}
