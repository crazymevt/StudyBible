# Contributing to StudyBible

Welcome! When contributing to this repository or assisting with code generation, please follow these guidelines to ensure consistency and seamless automation.

## Git Commit Guidelines

We use specific prefixes in our commit messages. Our automated release script (`scripts/release.sh`) parses these prefixes to automatically generate a structured `changelog.json` and updates the in-app "What's New" dialog.

**You MUST use one of the following prefixes for all commits:**

- `feat:` or `feature:`
  - Use this for adding new features, UI components, or significant capabilities.
  - *Example:* `feat: Add global version tracker to App Drawer`
  - *Changelog Category:* **New Features**

- `fix:` or `bug:`
  - Use this for bug fixes, crash resolutions, or repairing broken logic.
  - *Example:* `fix: Correct streak calculation to include time tracker`
  - *Changelog Category:* **Bugfixes**

- `update:`, `refactor:`, `perf:`
  - Use this for general improvements, UI tweaks, performance enhancements, or code refactoring that aren't strictly new features or bug fixes.
  - *Example:* `update: Reorganize settings screen layout`
  - *Changelog Category:* **Updates**

- `chore:`
  - Use this for routine tasks, script updates, or release bumps. 
  - **Note:** Commits prefixed with `chore:` are intentionally filtered out and will *not* appear in the public changelog.
  - *Example:* `chore: Release version 26.6.20+1`

## Release Process

When you are ready to create a new release:
1. Ensure all your changes are committed using the prefixes above.
2. Run `./scripts/release.sh` from the root of the project.
3. The script will automatically calculate the new version tag, write the changelog, update `pubspec.yaml`, and create the Git commit and tag.
4. Run `git push && git push --tags` to publish.
