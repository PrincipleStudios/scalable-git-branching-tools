# Code Organization

As these tools have grown, so has the complexity of the codebase, and the needs
of the developers using these tools. Moving forward, each top-level
non-interactive script will be organized into the following steps:

1. Input validation and normalization
2. Gather present-state information
3. Determine all actions necessary based on present state
4. Resolve local actions
5. Finalize actions

Organizing like this will allow for additional support flags, such as:

- `-dryRun` to not synchronize results and get a list of actions that it would
  perform
- `-skipConflicts` to not merge conflicting branches and display a warning.
- `-noAbort` to prevent resetting after a conflicting merge, and potentially
  providing the future capability of a `tool-continue` script to continue
  resolivng conflicts.

## Actions

Actions will be tracked as basic objects with a `type` and other properties.
Actions can either be "local" actions or "finalization" actions.

### Local actions

Local actions are actions that must be performed locally to determine
further actions. This may include performing git merges, inspecting git logs,
etc. Local actions must not make alterations to any local or remote refs.

For example, an action to "merge feature/a into feature/b" would resolve to a
"push (result-of-merge) commit to feature/b" finalization action.

Local actions will execute sequentially.

### Finalization actions

Finalization actions are actions that make side-effects to the repository,
either remote or local. They should be kept to the last stage of the workflow.

## Step breakdown

### Input validation and normalization

Input validation will be done to verify all parameters are present and of the
appropriate types. (Most of this can be done via PowerShell.)

Normalization will include splitting comma-delimited strings into lists to
support calling PowerShell scripts from bash.

These utilities should be migrated to the `/utils/input` folder.

### Gather present-state information

Primarily, this stage includes loading configuration data and upstream branch
data. This should perform all the data gathering necessary to be able to perform
an automic operation.

Some steps that occur in this stage include:
- Load configuration
- Fetch remote refs
- Load data from _upstream branches
- Ensure the working directory is clean

These utilities should be migrated to the `/utils/loading` folder.

### Determine all actions necessary based on present state

This stage will combine the inputs and present state to create an array of
action objects to be executed in further steps.

In most cases, the actions can be defined as a templated JSON script, similar to
many build pipelines. This will be supported by a `/utils/scripting` set of
modules.

This stage will probably not have reusable components other than creating
actions, which can come from either the `/utils/actions/local` or
`/utils/actions/finalize` areas.

### Resolve local actions

Local actions are performed at this stage, mostly in an iterative loop. These
actions should all remain local only and not affect local branch names or
commits, operating in almost entirely a headless mode.

Local action resolvers should be nested under an `/utils/actions/local`
folder and registered with the `Invoke-LocalAction` module.

### Finalize actions

Once all actions have been resolved successfully, the side-effects on the final
repository may begin. Ideally, atomic actions like `git push --atomic` are
leveraged, but not all destinations support that.

Finalization action resolvers should be nested under an
`/utils/actions/finalize` folder and registered with a `Invoke-FinalizeAction`
module.

## Example

Under this methodology, the `git new` command would have the basic outline:

1. Input validation and normalization
    - Split upstream branches into array
    - Ensure branch names are valid (using `git check-ref-format`)
2. Gather present-state information
    - Fetch from the remote
    - Find upstream branches' configurations (recursively)
3. Build initial action list, which would include
    - Resolve commit hash for initial upstream branch
        - Merge in each other upstream (if any) - if these merges fail, this may abort the `new`
            - Push the new branch based on the final hash
        - Checkout the branch locally
    - Set upstream branches
4. Resolve local actions
    - `Invoke-LocalAction`
        - Create commit to track upstream branches in `_upstream`
        - Merge each branch into the previous hash, tracking the resulting hash
5. Finalize actions
    - `Invoke-FinalizeAction`
        - A single `git push` would set `_upstream` and create the new branch
        - Checkout the new branch
