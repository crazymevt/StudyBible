# StudyBible AI Rules

These rules are synthesized from `CLAUDE.md`, `CONTRIBUTING.md`, and `DESIGN.md` to guide agent behavior in this project. They apply globally to all AI assistance within this workspace.

## 1. Architecture & Layers
- **Layered Design**: `domain` (pure Dart) ← `data` (Drift/SQLite, IO, HTTP) ← `app` (Riverpod) ← `ui` (widgets).
- **Pure Domain**: The domain layer (`lib/domain/`) MUST remain pure Dart. Absolutely no `package:flutter` or `dart:io` imports are allowed. This is enforced by CI.
- **Thin UI**: Business logic belongs in the domain/app layers, not inside widget event handlers or UI files.
- **Abstract IO**: Platform IO (storage, DB, HTTP) must be abstracted behind interfaces.

## 2. State & Database
- **Two Databases**: Content (Bibles, dictionaries) and User Data (notes, journals) are stored in two separate databases with different lifecycles.
- **Sync-Friendly State**: Every user object is an addressable record with sync metadata (`id`, `updatedAt`, `deleted`). Never use monolithic blobs for user state.
- **Soft Deletes**: Deletions for synced user data must be tombstones (e.g., `deleted = true`), not hard deletes.
- **Riverpod State**: Use Riverpod for state management. Avoid coupling logic to `BuildContext`.

## 3. Code Generation
- Generated Drift/Riverpod code (`*.g.dart`) is committed to the repository.
- After changing a Drift table or Riverpod provider, always run:
  `dart run build_runner build --delete-conflicting-outputs`

## 4. Git Commits
Commits must use specific prefixes. The `scripts/release.sh` script parses these to build the changelog:
- **User-facing**: `feat:` / `feature:`, `fix:` / `bug:`, `update:`, `refactor:`, `perf:`
- **Internal (hidden from changelog)**: `chore:`, `dev:`, `doc:` / `docs:`

## 5. UI & Testing
- **Visual Verification**: Do not trust UI changes from code alone. Verify UI changes visually (e.g., via screenshots or user feedback).
- **Offline-first**: Ensure all features function correctly without a network connection.
