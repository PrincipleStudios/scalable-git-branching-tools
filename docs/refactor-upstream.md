# `git refactor-upstream`

Refactor upstream branches to redirect upstreams from "source" to "target".

Usage:

    git-refactor-upstream.ps1 [-source] <string> [-target] <string>
        (-remove|-rename|-combine) [-comment <string>] [-dryRun]

## Parameters

### `[-source] <string>`

The name of the old upstream branch.

### `[-target] <string>`

The name of the new upstream branch.

### `(-remove|-replace|-combine)`

One of -rename, -remove, or -combine must be specfied.

* `-remove` indicates that the source branch should be removed and old upstream
  branches can be ignored.
* `-rename` indicates that upstreams from the source branch should be
  transferred to the target branch; any upstreams of the target should be
  overwritten.
* `-combine` indicates that upstreams from both source and target should be
  combined into upstreams of the target branch.

The source and target branches _will not_ be updated as part of this command.

### `-comment <string>` (Optional)

_Aliases: -m, -message_

If specified, include this comment in the commit message for the upstream
tracking branch when pushing changes.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.

