# `git verify-updated`

Verifies that a branch is up-to-date with its upstream branches.

Usage:

    git-verify-updated.ps1 [-target <string>] [-recurse]

## Parameters

### `[-target] <string>` (Optional)

The branch name to check. If not specified, use the current branch.

### `[-recurse]` (Optional)

If specified, recursively check upstream branches. If not specified, will only check the first level of upstream branches.
