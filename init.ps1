#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/' -replace ' ', '\ '

# Configure tool settings
git config alias.tool-config "!$dir/git-tool-config.ps1"

# Allow self-updating on the current branch
git config alias.tool-update "!$dir/git-tool-update.ps1"

# Check the tool configuration for issues
git config alias.tool-audit "!$dir/git-tool-audit.ps1"

# Create a new branch
git config alias.new "!$dir/git-new.ps1"

# Update current branch from its upstream/parent branches
git config alias.pull-upstream "!$dir/git-pull-upstream.ps1"

# List branches directly upstream from a branch
git config alias.show-upstream "!$dir/git-show-upstream.ps1"

# Adds an upstream branch
git config alias.add-upstream "!$dir/git-add-upstream.ps1"

# Build a release candidate from other branches
git config alias.rc "!$dir/git-rc.ps1"

# Build a release candidate from other branches using interactive prompts
git config alias.rci "!$dir/git-rci.ps1"

# Verify that a branch has all of its upstream up-to-date
git config alias.verify-updated "!$dir/git-verify-updated.ps1"

# Release an RC branch to a service line
git config alias.release "!$dir/git-release.ps1"

# Show a graph of the upstreams
git config alias.graph-upstreams "!$dir/git-graph-upstreams.ps1"

# Show the upstreams that would confilict
git config alias.upstream-conflicts "!$dir/git-upstream-conflicts.ps1"

# Show a list of downstreams 
git config alias.show-downstream "!$dir/git-show-downstreams.ps1"

# Make a dot file of the upstreams
git config alias.dot-upstreams "!$dir/git-upstreams-as-dot.ps1"
