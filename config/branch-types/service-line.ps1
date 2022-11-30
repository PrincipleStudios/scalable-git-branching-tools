
function Format-GitServiceLine { return "main" }
function ConvertTo-GitServiceLineInfo { return @{ type = 'service-line' } }

$branchTypeServiceLine = @{
    type = "^(sl|service-line|serviceLine|main)$"
    regex = "^main$"
    build = 'Format-GitServiceLine'
    toInfo = 'ConvertTo-GitServiceLineInfo'
}
