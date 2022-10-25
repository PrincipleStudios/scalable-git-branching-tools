function Invoke-WriteTree([String[]]$treeEntries) {
    $InputVar = $treeEntries -join "`n"

    # Setup stdin\stdout redirection for our process
    $StartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo -Property @{
                    FileName = 'git'
                    UseShellExecute = $false
                    RedirectStandardInput = $true
                    RedirectStandardOutput = $true
                    Arguments = 'mktree'
                }

    # Create new process
    $Process = New-Object -TypeName System.Diagnostics.Process -Property @{ StartInfo = $StartInfo }
    # Start process
    [void]$Process.Start()

    # Pipe data
    $StdinStream = $Process.StandardInput.BaseStream
    $reader = New-Object System.IO.StreamReader($Process.StandardOutput.BaseStream)

    try
    {
        [byte[]]$InputBytes = [Text.Encoding]::UTF8.GetBytes($InputVar)
        $StdinStream.Write($InputBytes, 0, $InputBytes.Length)
        $StdinStream.Flush()
    }
    finally
    {
        # Close streams
        $StdinStream.Close()
    }

    $result = $reader.ReadToEnd().Trim()
    
    # Cleanup
    'Process', 'StdinStream', 'reader' |
        ForEach-Object {
            (Get-Variable $_ -ValueOnly).Dispose()
        }

    return $result
}