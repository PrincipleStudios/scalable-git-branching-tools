# `git rebuild-rc`

Recreate a branch from its upstream branches, possibly modifying the upstream
branches. Intended for creating release candidate branches.

Usage:

    git-rc.ps1 [-target] <string> [-with <string[]>] [-without <string[]>] [-comment <string>] [-dryRun] [-allowOutOfDate] [-allowNoUpstreams]

## Parameters

### `[-target] <string>`

The name of the new branch.

### `-with <string[]>`

_Aliases: -add, -addUpstream, -upstreamBranches_

Comma-delimited list of branches to add upstream of the rc when rebuilding

### `-without <string[]>`

_Aliases: -remoce, -removeUpstream_

Comma-delimited list of branches to remove upstream of the rc when rebuilding

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, adds to the commit message on the upstream tracking branch for
creating the RC branch.

### `-allowOutOfDate` (Optional)

Allows branches that are not up-to-date with their upstreams.

### `-allowNoUpstreams` (Optional)

Allows branches that do not have any upstreams.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.
