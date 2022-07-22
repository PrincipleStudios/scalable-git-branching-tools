BeforeAll {
    . $PSScriptRoot/Set-GitFiles.ps1
    . $PSScriptRoot/../TestUtils.ps1
}

Describe 'Set-GitFiles' {
    Context 'Validates in advance' {
        It 'verifies that a file and folder are not set at the same time' {
            Mock git {
                $Global:LASTEXITCODE = 1
            } -Verifiable
            
            {
                Set-GitFiles @{ 'foo' = 'something'; 'foo/bar' = 'something else' } -m 'Test' -branchName 'target' -remote 'origin'
            } | Should -Throw

            Should -Invoke -CommandName git -Times 0
        }
    }
    Context 'For new branch' {
        BeforeEach{
        }

        # It 'adds a single file at the root' {
        #     Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'
        # }
        # It 'adds a single file' {
        #     Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'
        # }
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'target' -remote 'origin'            
        # }
    }
    Context 'For an existing new branch' {
        BeforeEach{
        }

        # It 'adds a single file' {
        #     Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'  
        # }
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'target' -remote 'origin'            
        # }
        # It 'replaces a file' {
        #     Set-GitFiles @{ 'foo/baz' = 'something new' } -m 'Test' -branchName 'target' -remote 'origin'  
        # }
        # It 'replaces a file and adds a file' {
        #     Set-GitFiles @{ 'foo/bar' = 'something new'; 'foo/baz' = 'something blue' } -m 'Test' -branchName 'target' -remote 'origin'  
        # }
        # It 'removes a file' {
        #     Set-GitFiles @{ 'foo/baz' = $nil } -m 'Test' -branchName 'target' -remote 'origin'  
        # }
    }
}
