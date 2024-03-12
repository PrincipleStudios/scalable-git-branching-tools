# `git refactor-upstream`

Refactor upstream branches to redirect upstreams from "source" to "target".
* _All_ branches that previously used "source" as an upstream will now use
  "target" as an upstream instead.
* This command only alters the upstream configuration of branches. Put another
  way, it does not merge any changes from new upstreams, etc. into affected
  branches, nor does it actually delete a "removed" source.

Usage:

    git-refactor-upstream.ps1 [-source] <string> [-target] <string>
        (-remove|-rename|-combine) [-comment <string>] [-dryRun]

## Parameters

### `[-source] <string>`

The name of the old upstream branch.

### `[-target] <string>`

The name of the new upstream branch.

### `(-remove|-rename|-combine)`

One of -rename, -remove, or -combine must be specfied.

* `-remove` indicates that the source branch should be removed and old upstream
  branches can be ignored.
* `-rename` indicates that upstreams from the source branch should be
  transferred to the target branch; any upstreams of the target should be
  overwritten.
* `-combine` indicates that upstreams from both source and target should be
  combined into upstreams of the target branch.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, include this comment in the commit message for the upstream
tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.

