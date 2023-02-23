BeforeAll {
    . $PSScriptRoot/Set-GitFiles.ps1
    . $PSScriptRoot/../TestUtils.ps1

    # This command is more complex than I want to handle for low-level git commands in these tests
    . $PSScriptRoot/Invoke-WriteTree.ps1
    Mock -CommandName Invoke-WriteTree { throw "Unexpected parameters for Invoke-WriteTree: $treeEntries" }
}

Describe 'Set-GitFiles' {
    BeforeEach {
        . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
    }
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
            Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target -q' } { $global:LASTEXITCODE = 128 }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target^{tree} -q' } { $global:LASTEXITCODE = 128 }
        }

        It 'adds a single file at the root' {
            Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 'some-hash' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tfoo"
            } { return 'root-TREE' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test' } { 'new-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } { $global:LASTEXITCODE = 0 }

            Set-GitFiles @{ 'foo' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'

            Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } -Times 1
        }
        It 'adds a single file' {
            Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 'some-hash' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbar"
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo"
            } { return 'root-TREE' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test' } { 'new-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } { $global:LASTEXITCODE = 0 }

            Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'

            Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } -Times 1
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'target' -remote 'origin'
        # }
    }
    Context 'For an existing new branch' {
        BeforeEach{
            Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target -q' } { 'prev-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'rev-parse --verify origin/target^{tree} -q' } { 'prev-tree' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-hash`texisting" }
        }

        It 'adds a single file' {
            Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 'some-hash' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbar"
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo" `
                -AND $treeEntries -contains "100644 blob existing-hash`texisting"
            } { return 'root-TREE' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } { $global:LASTEXITCODE = 0 }

            Set-GitFiles @{ 'foo/bar' = 'something' } -m 'Test' -branchName 'target' -remote 'origin'

            Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } -Times 1
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'adds multiple files' {
        #     Set-GitFiles @{ 'foo/bar' = 'something'; 'foo/baz' = 'something else' } -m 'Test' -branchName 'target' -remote 'origin'
        # }
        It 'replaces a file' {
            Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-foo-hash`tfoo" }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree existing-foo-hash' } { "100644 blob old-baz-hash`tbaz" }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 'some-hash' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "100644 blob some-hash`tbaz" `
                    -AND $treeEntries.length -eq 1
            } { return 'foo-TREE' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries -contains "040000 tree foo-TREE`tfoo" `
                    -AND $treeEntries.length -eq 1
            } { return 'root-TREE' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } { $global:LASTEXITCODE = 0 }

            Set-GitFiles @{ 'foo/baz' = 'something new' } -m 'Test' -branchName 'target' -remote 'origin'

            Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } -Times 1
        }
        # TODO: looks like Pester's Mock doesn't support testing stdin, which this would really need for a proper test
        # It 'replaces a file and adds a file' {
        #     Set-GitFiles @{ 'foo/bar' = 'something new'; 'foo/baz' = 'something blue' } -m 'Test' -branchName 'target' -remote 'origin'
        # }
        It 'removes a file' {
            Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree prev-tree' } { "100644 blob existing-foo-hash`tfoo" }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'ls-tree existing-foo-hash' } { "100644 blob old-baz-hash`tbaz" }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'hash-object -w --stdin' } { 'some-hash' }
            Mock -CommandName Invoke-WriteTree -ParameterFilter {
                $treeEntries.length -eq 0
            } { return 'root-TREE' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'commit-tree root-TREE -m Test -p prev-commit-hash' } { 'new-commit-hash' }
            Mock git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } { $global:LASTEXITCODE = 0 }

            Set-GitFiles @{ 'foo/baz' = $nil } -m 'Test' -branchName 'target' -remote 'origin'

            Should -Invoke git -ParameterFilter { ($args -join ' ') -eq 'push origin new-commit-hash:target' } -Times 1
        }
    }
}
