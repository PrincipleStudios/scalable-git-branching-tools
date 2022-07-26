BeforeAll {
    . $PSScriptRoot/Invoke-TicketsToBranches.ps1
    . $PSScriptRoot/../TestUtils.ps1
        
}

Describe 'Invoke-TicketsToBranches' {
    BeforeAll {
        $branches = @(
            @{ remote = $nil; branch='feature/FOO-123'; type = 'feature'; ticket='FOO-123' }
            @{ remote = $nil; branch='feature/FOO-124-comment'; type = 'feature'; ticket='FOO-124'; comment='comment' }
            @{ remote = $nil; branch='feature/FOO-124_FOO-125'; type = 'feature'; ticket='FOO-125'; parents=@('FOO-124') }
            @{ remote = $nil; branch='feature/FOO-76'; type = 'feature'; ticket='FOO-76' }
            @{ remote = $nil; branch='feature/XYZ-1-services'; type = 'feature'; ticket='XYZ-1'; comment='services' }
            @{ remote = $nil; branch='main'; type = 'service-line' }
            @{ remote = $nil; branch='rc/2022-07-14'; type = 'rc'; comment='2022-07-14' }
            @{ remote = $nil; branch='integrate/FOO-125_XYZ-1'; type = 'integration'; tickets=@('FOO-125','XYZ-1') }
        )
    }

    It 'returns the main ticket on a feature branch' {
        Invoke-TicketsToBranches @('FOO-123') $branches | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-123')
    }
    It 'returns multiple branches' {
        Invoke-TicketsToBranches @('FOO-125','FOO-123') $branches | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-123','feature/FOO-124_FOO-125')
    }
    It 'all branches plus the integration branch' {
        Invoke-TicketsToBranches @('FOO-125','XYZ-1') $branches | ForEach-Object { $_.branch } | Should -Be @('feature/FOO-124_FOO-125','feature/XYZ-1-services','integrate/FOO-125_XYZ-1')
    }
}
