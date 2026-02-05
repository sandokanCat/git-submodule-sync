# Git Submodule Sync Automation

A professional shell script to automate the synchronization, initialization, and management of Git submodules with a high-intensity, expressive console interface.

## 🚀 Overview

[`sync-automation.sh`](./sync-automation.sh) is designed to streamline the workflow of projects using multiple submodules. It parses your [`.gitmodules`](./.gitmodules) file, ensures all modules are correctly initialized and downloaded, pulls the latest changes from their respective branches, and synchronizes everything with your main repository.

## ✨ Key Features

- **Dynamic Discovery**: Automatically detects and registers submodules defined in [`.gitmodules`](./.gitmodules) even if they haven't been cloned yet.
- **Ignore Logic Control**: Supports granular per-submodule synchronization levels (`none`, `dirty`, `all`) via the standard `ignore` property.
- **High-Intensity UI**: Uses a vivid ANSI color palette (Bright/Bold) for clear status reporting and professional terminal feedback.
- **Robust Error Handling**: Wraps the entire synchronization process in a fail-safe block with definitive success (`[DONE]`) or failure (`[ERROR]`) reporting.
- **Auto-Committing**: Optionally commits and pushes local changes within submodules to keep dependencies up to date.

## 🛠️ Installation

1. Clone this repository or copy [`sync-automation.sh`](./sync-automation.sh) to your project root.
2. Grant execution permissions:

   ```bash
   chmod +x sync-automation.sh
   ```

## 📋 Configuration

The script reads the standard [`.gitmodules`](./.gitmodules) file. You can control the behavior of each submodule using the `ignore` property:

```ini
[submodule "example-module"]
    path = examples/example-module
    url = https://github.com/user/example-module
    branch = main
    ignore = none  # Default: Full sync & auto-commit
```

### Ignore Levels

- **`none`**: (Default) Pulls remote changes and auto-commits local modifications.
- **`dirty`**: Pulls remote changes but ignores local modifications (won't auto-commit).
- **`all`**: Completely skips the submodule during the synchronization process.

## ⚡ Usage

Simply run the script from the root of your Git repository:

```bash
./sync-automation.sh
```

The script will:

1. Detect your repository name.
2. Iterate through all submodules.
3. Fetch/Pull the latest commits for the specified branches.
4. Handle local changes according to your `ignore` settings.
5. Update the submodule pointers in your main repository and push them.

## 📄 License

MIT © 2026 [sandokan.cat](https://sandokan.cat)

> *Use it. Modify it. Share it. Attribution is appreciated.*

<div align="center">
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
    </a>
</div>
