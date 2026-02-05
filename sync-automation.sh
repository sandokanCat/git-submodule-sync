#!/bin/bash

#
# sync-automation.sh – SUBMODULE SYNC AUTOMATION
#
# Author:  © 2026 sandokan.cat – https://sandokan.cat
# License: MIT – https://opensource.org/licenses/MIT
# Version: 1.3.0
# Date:    2026-02-05
#
# Description:
# This script parses .gitmodules, ensures submodules exist, updates them, and pushes changes.
# It respects the 'ignore' setting for each submodule (all, dirty, none).
#

set -euo pipefail

# === OUTPUT COLORS ===
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"
BOLD="\033[1m"

# === UTILITIES ===

print_step() {
    printf "\n%b=== %s ===%b\n" "$CYAN" "$1" "$NC"
}

# === MAIN LOGIC ===

# 1. Ensure we are in a git repository
if [ ! -d .git ]; then
    printf "%b[ERROR] Not a git repository.\n" "$RED" "$NC"
    exit 1
fi

sync_submodules() {
    # 2. Robustly parse .gitmodules using git config

    # Get all submodule names
    local submodule_names
    submodule_names=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $1}' | sed 's/^submodule\.//;s/\.path$//')

    for name in $submodule_names; do
        local path url branch ignore
        path=$(git config -f .gitmodules --get "submodule.$name.path")
        url=$(git config -f .gitmodules --get "submodule.$name.url")
        branch=$(git config -f .gitmodules --get "submodule.$name.branch" || echo "main")
        ignore=$(git config -f .gitmodules --get "submodule.$name.ignore" || echo "none")

        print_step "Processing submodule: $name"
        printf "Path:   %b$path%b\n" "$BOLD" "$NC"
        printf "URL:    %b$url%b\n" "$BOLD" "$NC"
        printf "Branch: %b$branch%b\n" "$BOLD" "$NC"
        printf "Ignore: %b$ignore%b\n" "$BOLD" "$NC"

        # Logic for 'ignore = all'
        if [ "$ignore" == "all" ]; then
            printf "%b[SKIP] Submodule %b$name%b is ignored=%b$ignore%b\n" "$YELLOW" "$BOLD" "$YELLOW" "$NC"
            continue
        fi

        # 3. Check if the submodule directory exists
        if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
            printf "%b[WARN] Submodule path %b$path%b is missing or empty. Adding/initializing%b\n" "$YELLOW" "$BOLD" "$NC"
            
            # Ensure parent directory exists
            mkdir -p "$(dirname "$path")"
            
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
            
            print_step "Syncing %b$path%b with branch %b$branch%b" "$BOLD" "$NC"
            git fetch origin
            git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
            git pull origin "$branch"
            
            # Check for local changes to push
            local has_changes
            has_changes=$(git status -s)

            if [[ -n "$has_changes" ]]; then
                if [ "$ignore" == "dirty" ]; then
                    printf "%b[WARN] Untracked/modified changes in %b$path%b ignored%b\n" "$YELLOW" "$BOLD" "$NC"
                else
                    print_step "Local changes detected in %b$path%b. Committing and pushing" "$BOLD" "$NC"
                    git add .
                    git commit -m "Automated sync: $(date)"
                    git push origin "$branch"
                fi
            else
                printf "%b[WARN] No local changes in %b$path%b\n" "$YELLOW" "$BOLD" "$NC"
            fi
            
            popd > /dev/null
        else
            printf "%b[ERROR] Failed to ensure submodule at %b$path%b exists.%b\n" "$RED" "$BOLD" "$NC" "$RED" "$NC"
            return 1
        fi
    done

    git add .

    if [[ -n $(git status --porcelain) ]]; then
        print_step "Committing changes in main repository"
        git commit -m "Automated submodule sync: $(date)"

        print_step "Pushing main repository"
        git push origin "$(git branch --show-current)"
    else
        printf "%b[WARN] No changes to commit in main repository%b\n" "$YELLOW" "$NC"
    fi
}

# EXECUTION WITH ERROR HANDLING (Try/Catch)
if sync_submodules; then
    # === SUMMARY SUCCESS ===
    print_step "Summary"
    printf "%b[DONE] All repositories are updated.%b\n\n" "$GREEN" "$NC"
else
    # === SUMMARY ERROR ===
    print_step "Summary"
    printf "%b[ERROR] Submodule synchronization failed.%b\n\n" "$RED" "$NC"
    exit 1
fi
