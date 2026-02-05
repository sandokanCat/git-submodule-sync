#!/bin/bash

#
# sync-automation.sh – SUBMODULE SYNC AUTOMATION
#
# Author:  © 2026 sandokan.cat – https://sandokan.cat
# License: MIT – https://opensource.org/licenses/MIT
# Version: 1.3.3
# Date:    2026-02-05
#
# Description:
# This script parses .gitmodules, ensures submodules exist, updates them, and pushes changes.
# It respects the 'ignore' setting for each submodule (all, dirty, none).
#

set -euo pipefail

# === OUTPUT COLORS (Vivid/Bold Palette) ===
# I use 1;3x codes to ensure colors are bright and bold consistently
# Standard colors (for labels) and Bold versions (for values)
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"
# Bold/Bright versions
B_GREEN="\033[1;32m"
B_YELLOW="\033[1;33m"
B_RED="\033[1;31m"
B_CYAN="\033[1;36m"

# === UTILITIES ===

print_step() {
    # Ensure the entire line including the decorations is colored
    printf "\n${B_CYAN}=== %s ===${NC}\n" "$*"
}

# === MAIN LOGIC ===

# 1. Ensure we are in a git repository
if [ ! -d .git ]; then
    printf "${B_RED}[ERROR] Not a git repository.${NC}\n"
    exit 1
fi

# Detect repository name
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url 2>/dev/null || pwd)")

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

        print_step "Processing: ${B_CYAN}$name${NC}"
        printf "${GREEN}Path:${NC}   ${B_GREEN}$path${NC}\n"
        printf "${GREEN}URL:${NC}    ${B_GREEN}$url${NC}\n"
        printf "${GREEN}Branch:${NC} ${B_GREEN}$branch${NC}\n"
        printf "${GREEN}Ignore:${NC} ${B_GREEN}$ignore${NC}\n"

        # Logic for 'ignore = all'
        if [ "$ignore" == "all" ]; then
            printf "${YELLOW}[SKIP] Submodule ${B_YELLOW}$name${YELLOW} is ignore=${B_YELLOW}$ignore${NC}\n"
            continue
        fi

        # 3. Check if the submodule directory exists
        if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
            printf "${YELLOW}[WARN] Submodule path ${B_YELLOW}$path${YELLOW} is missing or empty. Adding/initializing${NC}\n"
            
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
            
            git fetch origin
            git checkout "$branch" 2>/dev/null || git checkout -b "$branch" "origin/$branch"
            git pull origin "$branch"
            
            # Check for local changes to push
            local has_changes
            has_changes=$(git status -s)

            if [[ -n "$has_changes" ]]; then
                if [ "$ignore" == "dirty" ]; then
                    printf "${YELLOW}[WARN] Untracked/modified changes in ${B_YELLOW}$path${YELLOW} ignore=${B_YELLOW}$ignore${NC}\n"
                else
                    print_step "Local changes detected in ${B_CYAN}$path${NC}. Committing and pushing"
                    git add .
                    git commit -m "Automated sync: $(date)"
                    git push origin "$branch"
                fi
            else
                printf "${YELLOW}[WARN] No local changes in ${B_YELLOW}$path${NC}\n"
            fi
            
            popd > /dev/null
        else
            printf "${RED}[ERROR] Failed to ensure submodule at ${B_RED}$path${RED} exists.${NC}\n"
            return 1
        fi
    done

    git add .

    if [[ -n $(git status --porcelain) ]]; then
        print_step "Committing and Pushing changes in ${B_CYAN}$REPO_NAME${NC}"
        git commit -m "Automated submodule sync: $(date)"
        git push origin "$(git branch --show-current)"
    else
        print_step "Committing and Pushing changes in ${B_CYAN}$REPO_NAME${NC}"
        printf "${YELLOW}[WARN] No changes to commit in ${B_CYAN}$REPO_NAME${NC}\n"
    fi
}

# EXECUTION WITH ERROR HANDLING (Try/Catch)
if sync_submodules; then
    # === SUMMARY SUCCESS ===
    print_step "Summary"
    printf "${B_GREEN}[DONE] All repositories are updated.${NC}\n\n"
else
    # === SUMMARY ERROR ===
    print_step "Summary"
    printf "${B_RED}[ERROR] Submodule synchronization failed.${NC}\n\n"
    exit 1
fi
