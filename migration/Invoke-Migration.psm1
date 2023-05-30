
$migrations = @(
    @{
        commit = "699e4b7";
        script = {
            Write-Host "Migration from before the update-tool was added, also should never run"
        }
    }
)

function Invoke-Migration([Parameter(Mandatory)][String] $from) {
    foreach ($entry in $migrations.GetEnumerator()) {
        $newCommit = $entry.commit
        $scriptBlock = $entry.script

        $diff = git rev-list --count "^$from" $newCommit
        if ($diff -gt 0) {
            Write-Information "Running migration for $newCommit"
            & $scriptBlock
        } else {
            Write-Information "Skipping migration for $newCommit"
        }
    }
}
Export-ModuleMember -Function Invoke-Migration
