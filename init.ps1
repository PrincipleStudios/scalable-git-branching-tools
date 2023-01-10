#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/'

# Updates self
git config alias.tool-update "!$dir/init.ps1"

# Configure tool settings
git config alias.tool-config "!$dir/git-tool-config.ps1"

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

# Verify that a branch has all of its upstream up-to-date
git config alias.verify-updated "!$dir/git-verify-updated.ps1"

# Release an RC branch to a service line
git config alias.release "!$dir/git-release.ps1"
