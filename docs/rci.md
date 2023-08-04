# `git rci`

Interactively create a new branch from multiple upstream branches without changing the local branch. Intended for creating release candidate branches.

Usage:

    git-rci.ps1 [-target] <string> [-comment <string>] [-force]

## Parameters

### `[-target] <string>`

The name of the new branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, overrides the commit message on the upstream tracking branch for creating the RC branch.

### `[-force]` (Optional)

Forces an update of the RC branch. Use this if you are replacing the existing branch.
