function Invoke-PipeToProcess([System.Diagnostics.ProcessStartInfo]$ProcessStartInfo, [scriptblock]$Action) {
    $ProcessStartInfo.UseShellExecute = $false
    $ProcessStartInfo.RedirectStandardInput = $true
    $ProcessStartInfo.RedirectStandardOutput = $true
    $ProcessStartInfo.RedirectStandardError = $true

    $Process = $([System.Diagnostics.Process]::new())
    $Process.StartInfo = $ProcessStartInfo

    # Start process
    [void]$Process.Start()

    try {
        $result = & $Action `
            -StdinStream $Process.StandardInput.BaseStream `
            -StdoutStream $Process.StandardOutput.BaseStream `
            -StderrStream $Process.StandardError.BaseStream

        # TODO - do we need to provide the exit code, etc.? Maybe a switch for it?
        return $result
    } finally {
        $Process.Dispose()
    }
}

Export-ModuleMember -Function Invoke-PipeToProcess
