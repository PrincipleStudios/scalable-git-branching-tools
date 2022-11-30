
function Split-String([string[]]$strings) {
    return [String[]]($strings | ForEach-Object { $_.split(',') } | ForEach-Object { $_ })
}