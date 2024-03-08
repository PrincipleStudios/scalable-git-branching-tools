# `git refactor-upstream`

Refactor upstream branches to redirect upstreams from "source" to "target".

Usage:

    git-refactor-upstream.ps1 [-source] <string> [-target] <string>
        (-remove|-rename) [-dryRun]

## Parameters

### `[-source] <string>`

The name of the old upstream branch.

### `[-target] <string>`

The name of the new upstream branch.

### `(-remove|-replace)`

Either `-remove` or `-replace` must be specified.

* `-remove` indicates that the source branch should be removed and old upstream
  branches can be ignored.
* `-rename` indicates that upstreams from the source branch should be
  transferred to the target branch.

The source and target branches _will not_ be updated as part of this command.

### `-dryRun` (Optional)

If specified, only test merging, do not push the updates.
