# `git rc`

Create a new branch from multiple upstream branches without changing the local branch. Intended for creating release candidate branches.

Usage:

    git-rc.ps1 [-branchName] <string> [[-branches] <string[]>] [[-commitMessage] <string>] [-force] [-noFetch]

## Parameters

### `[-branchName] <string>`

The name of the new branch.

### `[-branches] <string[]>`

Comma-delimited list of branches to merge into the new branch.

### `[-commitMessage] <string>` (Optional)

If specified, overrides the commit message on the upstream tracking branch for creating the RC branch.

### `[-force]` (Optional)

Forces an update of the RC branch. Use this if you are replacing the existing branch.

### `[-noFetch]` (Optional)

If specified, skip fetching updates for the other upstream branches before creating the RC.
