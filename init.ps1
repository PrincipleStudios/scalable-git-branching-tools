#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/' -replace ' ', '\ '

# Configure tool settings
git config alias.tool-config "!$dir/git-tool-config.ps1"

# Allow self-updating on the current branch
git config alias.tool-update "!$dir/git-tool-update.ps1"

# Check the upstream branch configuration for branches that no longer exist
git config alias.tool-audit-prune "!$dir/git-tool-audit-prune.ps1"

# Check the upstream branch configuration for references to deeper upstreams and simplify
git config alias.tool-audit-simplify "!$dir/git-tool-audit-simplify.ps1"

# Create a new branch
git config alias.new "!$dir/git-new.ps1"

# Update current branch from its upstream/parent branches
git config alias.pull-upstream "!$dir/git-pull-upstream.ps1"

# List branches directly downstream from a branch
git config alias.show-downstream "!$dir/git-show-downstream.ps1"

# List branches directly upstream from a branch
git config alias.show-upstream "!$dir/git-show-upstream.ps1"

# Adds an upstream branch
git config alias.add-upstream "!$dir/git-add-upstream.ps1"

# Build a release candidate from other branches
git config alias.rc "!$dir/git-rc.ps1"

# Rebuild a branch from its upstreams
git config alias.rebuild-rc "!$dir/git-rebuild-rc.ps1"

# Verify that a branch has all of its upstream up-to-date
git config alias.verify-updated "!$dir/git-verify-updated.ps1"

# Refactor upstream branches to redirect upstreams from "source" to "target"
git config alias.refactor-upstream "!$dir/git-refactor-upstream.ps1"

# Release an RC branch to a service line
git config alias.release "!$dir/git-release.ps1"

# Get the git version and warn about older versions
$fullVersion = git version
[double]$ver = ((($fullVersion -split ' ')[2]) -split '\.',3 | Select-Object -First 2) -join '.'
if ($ver -lt 2.41) {
    throw "Git version installed should be at least 2.41 (found '$fullVersion'); unexpected issues may occur. Please update git."
}
