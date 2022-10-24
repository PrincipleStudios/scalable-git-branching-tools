# `git add-upstream`

Adds one or more upstream branches to an existing branch.

Usage:

    git-add-upstream.ps1 [-branches] <string[]> [-branchName <string>] [-commitMessage <string>] [-dryRun]

## Parameters

### `[-branches] <string[]>`

A comma-delimited list of branches to add upstream of the existing branch.

### `-branchName <string>` (Optional)

The existing branch to update. If not specified, use the current branch.

### `-commitMessage <string>` (Optional)

If specified, override the commit message for the upstream tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging changes, do not push the updates.
