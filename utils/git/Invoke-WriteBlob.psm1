Import-Module -Scope Local "$PSScriptRoot/../core.psm1"

function Invoke-WriteBlob([System.Byte[]]$inputBytes) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = 'hash-object -w --stdin'

    return Invoke-PipeToProcess `
        -ProcessStartInfo $startInfo `
        -Action {
            param([System.IO.Stream] $StdinStream, [System.IO.Stream] $StdoutStream)

            $reader = New-Object System.IO.StreamReader $StdoutStream

            try
            {
                $StdinStream.Write($inputBytes, 0, $inputBytes.Length)
                $StdinStream.Flush()
                $StdinStream.Close()
                return $reader.ReadToEnd().Trim()
            }
            finally
            {
                # Close streams
                $StdinStream.Close()
                $reader.Dispose()
            }
        }

    return $result
}

Export-ModuleMember -Function Invoke-WriteBlob
