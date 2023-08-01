# `git verify-updated`

Verifies that a branch is up-to-date with its upstream branches.

Usage:

    git-verify-updated.ps1 [-branchName <string>] [-noFetch] [-recurse]

## Parameters

### `[-branchName] <string>` (Optional)

The branch name to check. If not specified, use the current branch.

### `[-noFetch]` (Optional)

If specified, do not fetch latest from the remote before checking to see if everything is updated.

### `[-recurse]` (Optional)

If specified, recursively check upstream branches. If not specified, will only check the first level of upstream branches.
