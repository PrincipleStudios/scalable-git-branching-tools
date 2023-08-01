# `git new`

Creates a new branch and checks it out from the specified branches

Usage:

    git-new.ps1 [-branchName] <string> [-comment <string>] `
        [-upstreamBranches <string[]>]

## Parameters:

### `[-branchName] <string>`

Specifies the name of the branch.

### `[-comment] <string>` (Optional)

_Aliases: -m, -message_

Specifies a comment as part of the commit message for the upstream branch.

### `-upstreamBranches <string>` (Optional)

_Aliases: -u, -upstream, -upstreams_

A comma-delimited list of branches (without the remote, if applicable). If not specified, assumes the default service line (see [tool-config](./tool-config.md).)
