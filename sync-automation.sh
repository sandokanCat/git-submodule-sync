#!/bin/bash

# Submodule Sync Automation Script
# This script parses .gitmodules, updates submodules, and pushes changes.

set -e

# 1. Initialize and update submodules to ensure they are present
echo "Initializing and updating submodules..."
git submodule update --init --recursive

# 2. Parse .gitmodules to get paths and branches
# We look for lines containing 'path =' or 'branch ='
echo "Parsing .gitmodules..."

# Arrays to store paths and branches
paths=()
branches=()

while IFS= read -r line; do
    if [[ $line =~ path\ =\ (.*) ]]; then
        paths+=("${BASH_REMATCH[1]}")
    elif [[ $line =~ branch\ =\ (.*) ]]; then
        branches+=("${BASH_REMATCH[1]}")
    fi
done < .gitmodules

# Note: This simple parser assumes each submodule has a path and ideally a branch.
# If branch is missing, we'll default to 'main'.

for i in "${!paths[@]}"; do
    sub_path="${paths[$i]}"
    sub_branch="${branches[$i]:-main}"
    
    echo "---------------------------------------------------"
    echo "Processing submodule: $sub_path (branch: $sub_branch)"
    
    if [ -d "$sub_path" ]; then
        pushd "$sub_path" > /dev/null
        
        # Pull latest changes
        echo "Pulling latest changes in $sub_path..."
        git checkout "$sub_branch"
        git pull origin "$sub_branch"
        
        # Check for local changes to push
        if [[ -n $(git status -s) ]]; then
            echo "Local changes detected in $sub_path. Committing and pushing..."
            git add .
            git commit -m "Automated sync: $(date)"
            git push origin "$sub_branch"
        else
            echo "No local changes in $sub_path."
        fi
        
        popd > /dev/null
    else
        echo "Warning: Submodule path $sub_path does not exist."
    fi
done

echo "---------------------------------------------------"
echo "Updating main repository..."

# Stage updated submodule pointers
git add .

# Commit if there are changes
if [[ -n $(git status --porcelain) ]]; then
    echo "Committing changes in main repository..."
    git commit -m "Automated submodule sync: $(date)"
    echo "Pushing main repository..."
    git push origin "$(git branch --show-current)"
else
    echo "No changes to commit in main repository."
fi

echo "Done!"
