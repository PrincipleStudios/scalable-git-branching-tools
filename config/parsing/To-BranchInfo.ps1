. $PSScriptRoot/../Variables.ps1

function To-BranchInfo($branchName) {
    if ($branchName -eq 'main') {
        return @{ type = 'service-line' }
    }

    $parts = $branchName.Split('/')

    function To-FeatureBranchInfo($branchName) {
        if ($branchName -notmatch $featureBranchRegex) {
            return $nil
        }
        $result = @{ type = $Matches.type; ticket = $Matches.ticket }
        if ($Matches.comment -ne $nil) {
            $result.comment = $Matches.comment
        }
        if ($Matches.parentTickets -ne $nil) {
            $result.parents = ,($Matches.parentTickets.split('_') | Where-Object { $_ -ne "" })
        }
        return $result
    }

    function To-ReleaseCandidateBranchInfo($branchName) {
        if ($branchName -notmatch $rcBranchRegex) {
            return $nil
        }
        return @{ type = 'rc'; comment = $Matches.comment }
    }

    function To-IntegrationBranchInfo($branchName) {
        if ($branchName -notmatch $integrationBranchRegex) {
            return $nil
        }
        $result = @{ type = 'integration' }
        $result.tickets = ,($Matches.tickets.split('_') | Where-Object { $_ -ne "" })
        return $result
    }

    function To-InfrastructureBranchInfo($branchName) {
        if ($branchName -notmatch $infraBranchRegex) {
            return $nil
        }
        $result = @{ type = 'infrastructure'; comment = $Matches.comment }
        if ($Matches.tickets -ne $nil) {
            $result.tickets = ,($Matches.tickets.split('_') | Where-Object { $_ -ne "" })
        }
        return $result
    }

    switch ($parts[0]) {
        "feature" { return To-FeatureBranchInfo($branchName) }
        "bugfix" { return To-FeatureBranchInfo($branchName) }
        "rc" { return To-ReleaseCandidateBranchInfo($branchName) }
        "integrate" { return To-IntegrationBranchInfo($branchName) }
        "infra" { return To-InfrastructureBranchInfo($branchName) }

        # TODO: more types
        default { return $nil }
    }
}
