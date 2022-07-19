BeforeAll {
    . $PSScriptRoot/ConvertTo-BranchInfo.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'ConvertTo-BranchInfo' {
    It 'returns nil for malformed branches' {
        ConvertTo-BranchInfo 'master' | Should -Be $nil
    }
    
    It 'identifies main' {
        ConvertTo-BranchInfo 'main' | Should-BeObject @{ type = 'service-line' }
    }
    
    It 'identifies feature branches' {
        ConvertTo-BranchInfo 'feature/PS-123' | Should-BeObject @{ type = 'feature'; ticket='PS-123' }
        ConvertTo-BranchInfo 'feature/PS-123-with-comment' | Should-BeObject @{ type = 'feature'; ticket='PS-123'; comment='with-comment' }
        ConvertTo-BranchInfo 'feature/PS-123_PS-124' | Should-BeObject @{ type = 'feature'; ticket='PS-124'; parents=@('PS-123') }
        ConvertTo-BranchInfo 'feature/PS-123_PS-124-another-comment' | Should-BeObject @{ type = 'feature'; ticket='PS-124'; parents=@('PS-123'); comment='another-comment' }
        ConvertTo-BranchInfo 'feature/PS-123_PS-124_PS-125' | Should-BeObject @{ type = 'feature'; ticket='PS-125'; parents=@('PS-123','PS-124') }
        ConvertTo-BranchInfo 'feature/PS-123_PS-124_PS-125-longish' | Should-BeObject @{ type = 'feature'; ticket='PS-125'; parents=@('PS-123','PS-124'); comment='longish' }
    }

    It 'identifies bugfix branches' {
        ConvertTo-BranchInfo 'bugfix/PS-123' | Should-BeObject @{ type = 'bugfix'; ticket='PS-123' }
        ConvertTo-BranchInfo 'bugfix/PS-123-with-comment' | Should-BeObject @{ type = 'bugfix'; ticket='PS-123'; comment='with-comment' }
        ConvertTo-BranchInfo 'bugfix/PS-123_PS-124' | Should-BeObject @{ type = 'bugfix'; ticket='PS-124'; parents=@('PS-123') }
        ConvertTo-BranchInfo 'bugfix/PS-123_PS-124-another-comment' | Should-BeObject @{ type = 'bugfix'; ticket='PS-124'; parents=@('PS-123'); comment='another-comment' }
        ConvertTo-BranchInfo 'bugfix/PS-123_PS-124_PS-125' | Should-BeObject @{ type = 'bugfix'; ticket='PS-125'; parents=@('PS-123','PS-124') }
        ConvertTo-BranchInfo 'bugfix/PS-123_PS-124_PS-125-longish' | Should-BeObject @{ type = 'bugfix'; ticket='PS-125'; parents=@('PS-123','PS-124'); comment='longish' }
    }

    It 'identifies rc branches' {
        ConvertTo-BranchInfo 'rc/2022-07-14' | Should-BeObject @{ type = 'rc'; comment='2022-07-14' }
        ConvertTo-BranchInfo 'rc/2022-07-14.1' | Should-BeObject @{ type = 'rc'; comment='2022-07-14.1' }
    }

    It 'identifies integration branches' {
        ConvertTo-BranchInfo 'integrate/ABC-1234_ABC-1235' | Should-BeObject @{ type = 'integration'; tickets=@('ABC-1234','ABC-1235') }
        ConvertTo-BranchInfo 'integrate/ABC-1234_ABC-1235_XYZ-78' | Should-BeObject @{ type = 'integration'; tickets=@('ABC-1234','ABC-1235','XYZ-78') }
    }
    
    It 'identifies infrastructure branches' {
        ConvertTo-BranchInfo 'infra/button-component' | Should-BeObject @{ type = 'infrastructure'; comment='button-component' }
        ConvertTo-BranchInfo 'infra/refactor-plugin-api' | Should-BeObject @{ type = 'infrastructure'; comment='refactor-plugin-api' }
        ConvertTo-BranchInfo 'infra/update-typescript' | Should-BeObject @{ type = 'infrastructure'; comment='update-typescript' }
    }

}
