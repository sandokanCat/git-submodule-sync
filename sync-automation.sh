#!/bin/bash

#
# sync-automation.sh – SUBMODULE SYNC AUTOMATION
#
# Author:  © 2026 sandokan.cat – https://sandokan.cat
# License: MIT – https://opensource.org/licenses/MIT
# Version: 1.1.0
# Date:    2026-02-05
#
# Description:
# This script parses .gitmodules, ensures submodules exist, updates them, and pushes changes.
#

set -euo pipefail

# === OUTPUT COLORS ===
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"

# === UTILITIES ===

print_step() {
    printf "\n=== %s ===\n" "$1"
}

# 1. Ensure we are in a git repository
if [ ! -d .git ]; then
    printf "%b[ERROR] Not a git repository.\n" "$RED" "$NC"
    exit 1
fi

# 2. Robustly parse .gitmodules using git config
echo "Parsing .gitmodules and ensuring submodules are initialized..."

# Get all submodule names
submodule_names=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $1}' | sed 's/^submodule\.//;s/\.path$//')

for name in $submodule_names; do
    path=$(git config -f .gitmodules --get "submodule.$name.path")
    url=$(git config -f .gitmodules --get "submodule.$name.url")
    branch=$(git config -f .gitmodules --get "submodule.$name.branch" || echo "main")

    print_step "Processing submodule: $name"
    printf "Path:   %b$path%b\n" "$CYAN" "$NC"
    printf "URL:    %b$url%b\n" "$CYAN" "$NC"
    printf "Branch: %b$branch%b\n" "$CYAN" "$NC"

    # 3. Check if the submodule directory exists
    if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
        echo "Submodule path '$path' is missing or empty. Adding/initializing"
        
        # Ensure parent directory exists
        mkdir -p "$(dirname "$path")"
        
        # Try to add the submodule (in case it's not in the index)
        # If it's already in the index but missing on disk, 'git submodule update --init' handles it.
        if ! git submodule status "$path" >/dev/null 2>&1; then
            print_step "Registering and cloning new submodule"
            git submodule add -b "$branch" --force "$url" "$path"
        else
            print_step "Updating existing but missing submodule"
            git submodule update --init --recursive "$path"
        fi
    fi

    # 4. Sync logic
    if [ -d "$path" ]; then
        pushd "$path" > /dev/null
        
        # Ensure we are on the correct branch
        print_step "Syncing $path with branch $branch"
        git fetch origin
        git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
        git pull origin "$branch"
        
        # Check for local changes to push
        if [[ -n $(git status -s) ]]; then
            print_step "Local changes detected in $path. Committing and pushing..."
            git add .
            git commit -m "Automated sync: $(date)"
            git push origin "$branch"
        else
            echo "No local changes in $path."
        fi
        
        popd > /dev/null
    else
        printf "%b[ERROR] Failed to ensure submodule at $path exists.\n" "$RED" "$NC"
    fi
done

print_step "Updating main repository"

# 5. Stage updated submodule pointers
git add .

# Commit if there are changes
if [[ -n $(git status --porcelain) ]]; then
    echo "Committing changes in main repository"
    git commit -m "Automated submodule sync: $(date)"
    echo "Pushing main repository"
    git push origin "$(git branch --show-current)"
else
    echo "No changes to commit in main repository."
fi

# === SUMMARY ===
print_step "Summary"
printf "%b[DONE] All repositories are updated.%b\n" "$GREEN" "$NC"
