
$migrations = @(
    @{
        commit = "cd9b27ecd32526716f7b374ba05780ce49366cc8";
        script = {
            # This is a sample script. Unless someone manually checks out
            # 699e4b72 as main and runs `git tool-update`, no one will see or
            # run this script.

            Write-Host "Running migration, such as updating local configuration."

            # Migrations can do things like one-time `git config` changes in
            # case our keys change, or adding in upstream tracking support for
            # multiple remotes, etc. This should consider local only to being on
            # the given version; remote does not (at this time) have a version
            # indicator, and will need that to be added for migrations first.
        }
    }
)

function Invoke-Migration([Parameter(Mandatory)][String] $from) {
    foreach ($entry in $migrations.GetEnumerator()) {
        $newCommit = $entry.commit
        $scriptBlock = $entry.script

        $diff = git rev-list --count ^$from $newCommit
        if ($Global:LASTEXITCODE -ne 0) {
            throw "Unable to run migrations; could not detect what was previously included"
        }
        if ($diff -gt 0) {
            Write-Debug "Running migration for $newCommit"
            & $scriptBlock
        } else {
            Write-Debug "Skipping migration for $newCommit"
        }
    }
}
Export-ModuleMember -Function Invoke-Migration
