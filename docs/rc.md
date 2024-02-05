# `git rc`

Create a new branch from multiple upstream branches without changing the local
branch. Intended for creating release candidate branches.

Usage:

    git-rc.ps1 [-target] <string> [-upstreamBranches <string[]>] [-comment <string>] [-force] [-dryRun] [-allowOutOfDate] [-allowNoUpstreams]

## Parameters

### `[-target] <string>`

The name of the new branch.

### `-upstreamBranches <string[]>`

_Aliases: -u, -upstream, -upstreams_

Comma-delimited list of branches to merge into the new branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, adds to the commit message on the upstream tracking branch for
creating the RC branch.

### `-force` (Optional)

Forces an update of the RC branch. Use this if you are replacing the existing
branch.

### `-allowOutOfDate` (Optional)

Allows branches that are not up-to-date with their upstreams. (This is the old
behavior.)

### `-allowNoUpstreams` (Optional)

Allows branches that do not have any upstreams. (This is the old behavior.)

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.
