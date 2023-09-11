Describe 'Invoke-PipeToProcess' {
    BeforeAll {
        Import-Module -Scope Local "$PSScriptRoot/Invoke-PipeToProcess.psm1"
    }

    It 'can return data from stdout' {
        $result = Invoke-PipeToProcess `
            -ProcessStartInfo $(New-Object -TypeName System.Diagnostics.ProcessStartInfo -Property @{
                FileName = 'git'
                Arguments = '--version'
            }) `
            -Action {
                param([System.IO.Stream] $StdoutStream)

                $reader = New-Object System.IO.StreamReader $StdoutStream
                try
                {
                    return $reader.ReadToEnd().Trim()
                }
                finally
                {
                    $reader.Dispose()
                }
            }
        $result | Should -BeLike 'git version *'
    }

    It 'can pass data to git stdin' {
        $result = Invoke-PipeToProcess `
            -ProcessStartInfo $(New-Object -TypeName System.Diagnostics.ProcessStartInfo -Property @{
                FileName = 'git'
                Arguments = 'hash-object --stdin --no-filters --literally'
            }) `
            -Action {
                param([System.IO.Stream] $StdoutStream, [System.IO.Stream] $StdinStream)

                $writer = [System.IO.StreamWriter]::new($StdinStream, [Text.Encoding]::Ascii)
                $reader = New-Object System.IO.StreamReader $StdoutStream
                try
                {
                    $writer.Write('hello world')
                    $writer.Flush()
                    $writer.Close()
                    return $reader.ReadToEnd().Trim()
                }
                finally
                {
                    $writer.Dispose()
                    $reader.Dispose()
                }
            }
        $result | Should -Be '95d09f2b10159347eece71399a7e2e907ea3df4f' # hash of 'hello world'
    }
}