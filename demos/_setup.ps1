#!/usr/bin/env pwsh

git status 2> $nil
if ($global:LASTEXITCODE -eq 0) { throw 'Must not be in a git directory' }

Push-Location
try {
    mkdir origin
    cd origin

    git init
    /git-tools/init.ps1

    echo "existing-item" > existing-item.txt
    git add .
    git commit -m "Add existing-item.txt"
    git branch -M main

    git checkout -B feature/add-item-1
    echo "new-item-1" > new-item-1.txt
    git add .
    git commit -m "Add new-item-1.txt"

    git checkout -B feature/add-item-2 main
    echo "new-item-2" > new-item-2.txt
    git add .
    git commit -m "Add new-item-2.txt"

    git checkout -B feature/change-existing-item-A main
    echo "change A" > existing-item.txt
    git add .
    git commit -m "Apply change A"

    git checkout -B feature/change-existing-item-B main
    echo "change B" > existing-item.txt
    git add .
    git commit -m "Apply change B"

    git checkout (git rev-parse main)

} finally {
    Pop-Location
}
