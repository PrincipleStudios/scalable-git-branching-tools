BeforeAll {
    . $PSScriptRoot/Select-Branches.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Select-Branches' {
    BeforeEach{
        Mock git { # remote -r
            Write-Output "
            origin/feature/FOO-123
            origin/feature/FOO-124-comment
            origin/feature/FOO-124_FOO-125
            origin/main
            origin/rc/2022-07-14
            "
        }
        
        $branches = Select-Branches
    }

    It 'includes feature FOO-123' {
        $branches | Where-Object { $_.branch -eq 'feature/FOO-123' } 
            | Should-BeObject @{ branch = 'feature/FOO-123'; remote = 'origin'; type = 'feature'; ticket = 'FOO-123' }
    }
    It 'includes feature FOO-124' {
        $branches | Where-Object { $_.branch -eq 'feature/FOO-124-comment' } 
            | Should-BeObject @{ branch = 'feature/FOO-124-comment'; remote = 'origin'; type = 'feature'; ticket = 'FOO-124'; comment = 'comment' }
    }
    It 'includes feature FOO-125' {
        $branches | Where-Object { $_.branch -eq 'feature/FOO-124_FOO-125' } 
            | Should-BeObject @{ branch = 'feature/FOO-124_FOO-125'; remote = 'origin'; type = 'feature'; ticket = 'FOO-125'; parents = @( 'FOO-124' ) }
    }
    It 'includes rc 2022-07-14' {
        $branches | Where-Object { $_.branch -eq 'rc/2022-07-14' } 
            | Should-BeObject @{ branch = 'rc/2022-07-14'; remote = 'origin'; type = 'rc'; comment = '2022-07-14' }
    }
    It 'includes main' {
        $branches | Where-Object { $_.branch -eq 'main' } 
            | Should-BeObject @{ branch = 'main'; remote = 'origin'; type = 'service-line' }
    }
}
