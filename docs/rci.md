# `git rci`

Interactively create a new branch from multiple upstream branches without changing the local branch. Intended for creating release candidate branches.

Usage:

    git-rci.ps1 [-branchName] <string> [[-commitMessage] <string>] [-force] [-noFetch]

## Parameters

### `[-branchName] <string>`

The name of the new branch.

### `[-commitMessage] <string>` (Optional)

If specified, overrides the commit message on the upstream tracking branch for creating the RC branch.

### `[-force]` (Optional)

Forces an update of the RC branch. Use this if you are replacing the existing branch.

### `[-noFetch]` (Optional)

If specified, skip fetching updates for the other upstream branches before creating the RC.
