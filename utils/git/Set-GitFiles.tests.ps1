BeforeAll {
    Import-Module -Scope Local "$PSScriptRoot/Set-GitFiles.psm1"
    Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
}

Describe 'Set-GitFiles' {
    BeforeEach {
        Register-Framework
    }

    Context 'Validates in advance' {
        It 'verifies that a file and folder are not set at the same time' {
            Mock git {
                $Global:LASTEXITCODE = 1
            } -Verifiable

            {
                Set-GitFiles @{ 'foo' = 'something'; 'foo/bar' = 'something else' } -m 'Test' -branchName 'origin/target'
            } | Should -Throw

            Should -Invoke -CommandName git -Times 0
        }
    }
    Context 'For new branch' {
        BeforeEach{
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target -q' } { $global:LASTEXITCODE = 128 }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target^{tree} -q' } { $global:LASTEXITCODE = 128 }
        }

        It 'adds a single file at the root' {
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes('something')) 'some-hash'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tfoo"
            } { return 'root-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test' } { 'new-commit-hash' }

            Set-GitFiles @{ 'foo' = 'something' } -m 'Test' -branchName 'origin/target'
        }
        It 'adds a single file' {
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes('something')) 'some-hash'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbar"
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo"
            } { return 'root-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test' } { 'new-commit-hash' }

            Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'origin/target'
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'origin/target'
        # }
    }
    Context 'For an existing new branch' {
        BeforeEach{
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target -q' } { 'prev-commit-hash' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target^{tree} -q' } { 'prev-tree' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-hash`texisting" }
        }

        It 'adds a single file' {
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes('something')) 'some-hash'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbar"
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo" `
                -AND $treeEntries -contains "100644 blob existing-hash`texisting"
            } { return 'root-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }

            Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'origin/target'
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'origin/target'
        # }
        It 'replaces a file' {
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-foo-hash`tfoo" }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree existing-foo-hash' } { "100644 blob old-baz-hash`tbaz" }
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes('something new')) 'some-hash'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbaz" `
                    -AND $treeEntries.length -eq 1
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo" `
                    -AND $treeEntries.length -eq 1
            } { return 'root-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }

            Set-GitFiles @{ 'foo/baz' = 'something new' } -m 'Test' -branchName 'origin/target'
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'replaces a file and adds a file' {
        #     Set-GitFiles @{ 'foo/bar' = 'something new'; 'foo/baz' = 'something blue' } -m 'Test' -branchName 'origin/target'
        # }
        It 'removes a file' {
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-foo-hash`tfoo" }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'ls-tree existing-foo-hash' } { "100644 blob old-baz-hash`tbaz" }
            Initialize-WriteBlob ([Text.Encoding]::UTF8.GetBytes('something')) 'some-hash'
            Mock -CommandName Invoke-WriteTree -ModuleName 'Set-GitFiles' -ParameterFilter {
                $treeEntries.length -eq 0
            } { return 'root-TREE' }
            Mock git -ModuleName 'Set-GitFiles' -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }

            Set-GitFiles @{ 'foo/baz' = $nil } -m 'Test' -branchName 'origin/target'
        }
    }
}
