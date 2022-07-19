
function Format-GitServiceLine { return "main" }
function ConvertTo-GitServiceLineInfo { return @{ type = 'service-line' } }

$branchTypeServiceLine = @{
    regex = "^main$"
    build = 'Format-GitServiceLine'
    toInfo = 'ConvertTo-GitServiceLineInfo'
}
