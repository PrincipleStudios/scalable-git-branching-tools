#!/usr/bin/env pwsh

Param(
    [Parameter()][String] $remote
)

$remotes = git remote
if ($remote -ne '' -AND $remotes -notcontains $remote) {
    throw "$remote not a valid remote for the repo."
} elseif ($remote -ne '') {
    git config scaled-git.remote $remote
}
