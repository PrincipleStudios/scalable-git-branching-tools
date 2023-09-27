Import-Module -Scope Local "$PSScriptRoot/../core.psm1"

function Invoke-WriteTree([String[]]$treeEntries) {
    $InputVar = $treeEntries -join "`n"

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = 'mktree'

    return Invoke-PipeToProcess `
        -ProcessStartInfo $startInfo `
        -Action {
            param([System.IO.Stream] $StdinStream, [System.IO.Stream] $StdoutStream)

            $reader = New-Object System.IO.StreamReader $StdoutStream

            try
            {
                [byte[]]$InputBytes = [Text.Encoding]::UTF8.GetBytes($InputVar)
                $StdinStream.Write($InputBytes, 0, $InputBytes.Length)
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

Export-ModuleMember -Function Invoke-WriteTree
