#!/usr/bin/env pwsh

$dir = $PSScriptRoot -replace '\\','/'

# Updates self
git config alias.tool-update "!$dir/init.ps1"

# Configure tool settings
git config alias.tool-config "!$dir/git-tool-config.ps1"

# Create a new branch
git config alias.new "!$dir/git-new.ps1"

# Find a branch?? Is this useful?
git config alias.find-branch "!$dir/git-find-branch.ps1"

# TODO: 
# - rc generation
# - update branch process
# - rc verification/release
# - ???