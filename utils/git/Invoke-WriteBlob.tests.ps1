Describe 'Invoke-WriteBlob' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/../framework.mocks.psm1"
        Import-Module -Scope Local "$PSScriptRoot/../core/Invoke-PipeToProcess.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteBlob.psm1"
        Import-Module -Scope Local "$PSScriptRoot/Invoke-WriteBlob.mocks.psm1"
    }

    BeforeEach {
        Register-Framework
    }

    It 'passes data as-is' {
        $testable = @{}
        $inputs = [Text.Encoding]::UTF8.GetBytes('foo')
        $outputs = 'expected-hash'
        Mock -ModuleName Invoke-WriteBlob -CommandName Invoke-PipeToProcess -MockWith {
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

                $testable.inputResult = $StdIn.ToArray()
            } finally {
                $streamWriter.Dispose()
                $StdIn.Dispose()
                $StdOut.Dispose()
                $StdErr.Dispose()
            }
        }

        $resultCommit = Invoke-WriteBlob $inputs

        $resultCommit | Should -Be $outputs
        $testable.inputResult | Should -Be $inputs
    }

    It 'has a very simple mock' {
        $inputs = [Text.Encoding]::UTF8.GetBytes('foo')
        $outputs = 'expected-hash'
        Lock-InvokeWriteBlob
        Initialize-WriteBlob -inputBytes $inputs -resultSha $outputs

        $resultCommit = Invoke-WriteBlob $inputs

        $resultCommit | Should -Be $outputs
    }

    It 'still checks parameter inputs match' {
        $inputs = [Text.Encoding]::UTF8.GetBytes('foo')
        $wrongInputs = [Text.Encoding]::UTF8.GetBytes('bar')
        $outputs = 'bad-hash'
        Lock-InvokeWriteBlob
        Initialize-WriteBlob -inputBytes $wrongInputs -resultSha $outputs

        { Invoke-WriteBlob $inputs } | Should -Throw 'Invoke-WriteBlob was not set up for this test'
    }
}