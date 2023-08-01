# `git add-upstream`

Adds one or more upstream branches to an existing branch.

Usage:

    git-add-upstream.ps1 [-upstreamBranches] <string[]> [-target <string>] [-comment <string>] [-dryRun]

## Parameters

### `[-upstreamBranches] <string[]>`

_Aliases: -u, -upstream, -upstreams_

A comma-delimited list of branches to add upstream of the existing branch.

### `-target <string>` (Optional)

The existing branch to update. If not specified, use the current branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, include this comment in the commit message for the upstream tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging changes, do not push the updates.
