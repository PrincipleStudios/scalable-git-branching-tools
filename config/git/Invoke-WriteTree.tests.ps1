Describe 'Invoke-WriteTree' {
    BeforeAll {
        . "$PSScriptRoot/../testing/Lock-Git.mocks.ps1"
        Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-PipeToProcess.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteTree.mocks.psm1"
    }

    It 'passes the tree entries as-is in UTF8 format' {
        $testable = @{}
        $inputs = @("040000 tree foo-TREE`tfoo", "100644 blob some-hash`tfoo")
        $outputs = 'expected-hash'
        Mock -ModuleName Invoke-WriteTree -CommandName Invoke-PipeToProcess -MockWith {
            $StdIn = New-Object System.IO.MemoryStream
            $StdOut = New-Object System.IO.MemoryStream
            $StdErr = New-Object System.IO.MemoryStream
            $streamWriter = New-Object System.IO.StreamWriter $StdOut
            try {
                $streamWriter.Write($outputs)
                $streamWriter.Flush()
                $StdOut.Position = 0

                & $Action `
                    -StdinStream $StdIn `
                    -StdoutStream $StdOut `
                    -StderrStream $StdErr

                $testable.inputResult = [Text.Encoding]::UTF8.GetString($StdIn.ToArray())
            } finally {
                $streamWriter.Dispose()
                $StdIn.Dispose()
                $StdOut.Dispose()
                $StdErr.Dispose()
            }
        }

        $resultCommit = Invoke-WriteTree $inputs

        $resultCommit | Should -Be $outputs
        $testable.inputResult | Should -Be $($inputs -join "`n")
    }

    It 'has a very simple mock' {
        $inputs = @("040000 tree foo-TREE`tfoo", "100644 blob some-hash`tfoo")
        $outputs = 'expected-hash'
        Lock-InvokeWriteTree
        Initialize-WriteTree -treeEntries $inputs -resultSha $outputs

        $resultCommit = Invoke-WriteTree $inputs

        $resultCommit | Should -Be $outputs
    }

    It 'still checks parameter inputs match' {
        $inputs = @("040000 tree foo-TREE`tfoo", "100644 blob some-hash`tfoo")
        $wrongInputs = @("040000 tree foo-TREE`tfoo")
        $outputs = 'bad-hash'
        Lock-InvokeWriteTree
        Initialize-WriteTree -treeEntries $wrongInputs -resultSha $outputs

        { Invoke-WriteTree $inputs } | Should -Throw 'Invoke-WriteTree was not set up for this test'
    }
}