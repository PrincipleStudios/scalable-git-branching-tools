# `git tool-audit-prune`

Removes upstream branch configuration for branches that no longer exist.

Usage:

    git-tool-audit-prune.ps1 [-noFetch] [-dryRun] [-quiet]

## Parameters

## `-noFetch` (Optional)

By default, all scripts fetch the latest before processing. To skip this (which
was the old behavior), include `-noFetch`.

### `-dryRun` (Optional)

If specified, changes to branches will be displayed but no actual changes will
be applied.

## `-quiet` (Optional)

Suppress unnecessary output. Useful when a tool is designed to consume the
output of this script via git rather than via PowerShell.
