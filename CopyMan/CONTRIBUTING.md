# Contributing to CopyMan

First off, thank you for considering contributing to CopyMan! It's people like you that make CopyMan such a great tool. 🎉

We welcome all types of contributions — bug reports, feature requests, documentation improvements, code contributions, and more. This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Your First Code Contribution](#your-first-code-contribution)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to richesh.gupta@example.com.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/richeshgupta/CopyMan/issues) to avoid duplicates. When you create a bug report, include as many details as possible:

**Use the bug report template** which includes:

- **Clear, descriptive title** - Use a clear and descriptive title for the issue
- **Steps to reproduce** - Provide specific steps to reproduce the behavior
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Screenshots** - If applicable, add screenshots to help explain the problem
- **Environment details**:
  - OS (Linux distribution, macOS version, Windows version)
  - Flutter version (`flutter --version`)
  - CopyMan version
- **Additional context** - Any other context about the problem

**Example:**

```
Title: Clipboard not capturing text from Firefox on Ubuntu 22.04

**Steps to reproduce:**
1. Open Firefox
2. Copy text with Ctrl+C
3. Open CopyMan with Ctrl+Alt+V
4. The copied text is not in the history

**Expected:** Text should appear in clipboard history
**Actual:** Text does not appear

**Environment:**
- OS: Ubuntu 22.04 LTS
- Flutter: 3.38.9
- CopyMan: v0.1.0

**Additional context:** Works fine with Chrome and VS Code
```

### Suggesting Features

We love to hear ideas for new features! Feature requests are tracked as [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions).

Before creating a feature request:
- Check the [roadmap](README.md#-roadmap) to see if it's already planned
- Search [existing discussions](https://github.com/richeshgupta/CopyMan/discussions) to avoid duplicates

When suggesting a feature, include:
- **Clear use case** - Why is this feature useful?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you think about?
- **Additional context** - Screenshots, mockups, or examples from other apps

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:
- `good first issue` - Simple issues perfect for newcomers
- `help wanted` - Issues where we'd appreciate community help
- `documentation` - Documentation improvements

**Never contributed to open source before?** Check out [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/).

## Development Setup

### Prerequisites

#### Linux (recommended for development)
```bash
# Install Flutter dependencies
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsqlite3-dev xdotool x11-utils xclip xprop

# Install Flutter (if not already installed)
# Follow: https://docs.flutter.dev/get-started/install/linux
```

#### macOS
```bash
# Install Xcode command-line tools
xcode-select --install

# Install Flutter
# Follow: https://docs.flutter.dev/get-started/install/macos
```

#### Windows
```bash
# Install Visual Studio Build Tools or MinGW
# Follow: https://docs.flutter.dev/get-started/install/windows
```

### Required Versions
- **Flutter:** 3.38.9 or higher
- **Dart:** 3.10.8 or higher (bundled with Flutter)

Verify installation:
```bash
flutter --version
```

### Fork and Clone

1. **Fork the repository** on GitHub (click the Fork button)

2. **Clone your fork:**
```bash
git clone https://github.com/YOUR-USERNAME/CopyMan.git
cd CopyMan/copyman
```

3. **Add upstream remote:**
```bash
git remote add upstream https://github.com/richeshgupta/CopyMan.git
```

4. **Install dependencies:**
```bash
flutter pub get
```

5. **Verify everything works:**
```bash
# Run tests
flutter test

# Run the app in debug mode
flutter run -d linux  # or 'macos' or 'windows'
```

## Development Workflow

### Creating a Feature Branch

Always create a new branch for your work:

```bash
# Update your main branch
git checkout master
git pull upstream master

# Create a feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

**Branch naming conventions:**
- `feature/short-description` - For new features
- `fix/issue-123-short-description` - For bug fixes
- `docs/what-you-changed` - For documentation
- `refactor/component-name` - For refactoring

### Testing Your Changes

Before submitting, ensure:

```bash
# Run all tests
flutter test

# Run code analysis
flutter analyze lib/

# Format code
dart format lib/

# Build release binary (to verify builds work)
flutter build linux --release  # or macos/windows
```

### Keeping Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Update your main branch
git checkout master
git merge upstream/master

# Rebase your feature branch (if needed)
git checkout feature/your-feature
git rebase master
```

## Coding Standards

We follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines. Key principles:

### Code Style

- **Use `dart format`** - Always format before committing:
  ```bash
  dart format lib/
  ```

- **Naming conventions:**
  - Classes: `PascalCase` (e.g., `ClipboardService`)
  - Variables, functions: `camelCase` (e.g., `getClipboardHistory`)
  - Constants: `lowerCamelCase` (e.g., `defaultPollingInterval`)
  - Private members: prefix with `_` (e.g., `_internalState`)

- **File organization:**
  - One class per file (exceptions: small related classes)
  - File names: `snake_case.dart` (e.g., `clipboard_service.dart`)

### Code Organization

- **Keep files focused** - Each file should have a single responsibility
- **Use meaningful names** - Names should be self-documenting
- **Add comments sparingly** - Code should be self-explanatory; comment only "why", not "what"
- **Prefer composition over inheritance** - Use mixins and composition patterns

### Flutter-Specific

- **Use StatelessWidget when possible** - Only use StatefulWidget when state is needed
- **Extract reusable widgets** - Keep widget trees shallow
- **Use const constructors** - Mark widgets `const` when possible for performance
- **Dispose resources** - Always dispose controllers, streams, etc. in `dispose()`

### Example

```dart
/// Manages clipboard history persistence using SQLite.
///
/// This service provides CRUD operations for clipboard items and handles
/// database schema migrations.
class StorageService {
  // Private constructor for singleton pattern
  StorageService._();
  static final instance = StorageService._();

  Database? _database;

  /// Initializes the SQLite database.
  ///
  /// Creates tables if they don't exist and runs any pending migrations.
  Future<void> initialize() async {
    // Implementation...
  }

  /// Retrieves all clipboard items, ordered by timestamp descending.
  Future<List<ClipboardItem>> getAllItems() async {
    // Implementation...
  }
}
```

## Commit Message Guidelines

We follow conventional commit format for clear, searchable history:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring (no feature change or bug fix)
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build config)

### Examples

```bash
feat(clipboard): add support for image capture

Implements image clipboard monitoring using platform-specific APIs.
Images are stored as Base64 in SQLite with thumbnail generation.

Closes #42

---

fix(search): resolve fuzzy search ranking issue

Fixed bug where short matches ranked lower than long matches.
Updated scoring algorithm to prioritize shorter strings.

Fixes #128

---

docs(readme): update installation instructions for macOS

Added instructions for Apple Silicon Macs and updated
Xcode requirements.

---

refactor(storage): extract database schema to separate file

Moved schema constants and migrations to schema.dart for
better organization and maintainability.
```

### Rules

- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter of subject
- No period at the end of subject
- Limit subject line to 50 characters
- Wrap body at 72 characters
- Reference issues/PRs in footer

## Pull Request Process

### Before Submitting

1. **Ensure tests pass:**
   ```bash
   flutter test
   flutter analyze lib/
   ```

2. **Format your code:**
   ```bash
   dart format lib/
   ```

3. **Update documentation** if needed (README, code comments)

4. **Rebase on latest master:**
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Creating the Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill out the PR template:
   - **Title:** Clear, descriptive title (follows commit message style)
   - **Description:** What changes were made and why
   - **Related issues:** Link issues with "Closes #123" or "Fixes #456"
   - **Screenshots:** For UI changes, include before/after screenshots
   - **Testing:** Describe how you tested the changes
   - **Checklist:** Complete the checklist in the template

### PR Review Process

- A maintainer will review your PR within 3-5 business days
- Address any requested changes by pushing new commits
- Once approved, a maintainer will merge your PR
- Your contribution will be included in the next release

### PR Guidelines

- **Keep PRs focused** - One feature or fix per PR
- **Small is better** - Break large features into smaller PRs
- **Update tests** - Add/update tests for your changes
- **No breaking changes** - Avoid breaking existing APIs without discussion
- **Be responsive** - Reply to review comments within a reasonable time

## Project Structure

Understanding the codebase structure will help you navigate:

```
copyman/
├── lib/
│   ├── main.dart                   # Entry point
│   ├── app.dart                    # MaterialApp setup
│   ├── models/                     # Data models
│   │   ├── clipboard_item.dart     # ClipboardItem model
│   │   ├── group.dart              # Group/folder model
│   │   └── sequence_session.dart   # Sequential paste session
│   ├── services/                   # Business logic layer
│   │   ├── storage_service.dart    # SQLite persistence
│   │   ├── clipboard_service.dart  # Clipboard monitoring
│   │   ├── hotkey_service.dart     # Global hotkey registration
│   │   ├── tray_service.dart       # System tray management
│   │   ├── group_service.dart      # Group operations
│   │   ├── sequence_service.dart   # Sequential paste logic
│   │   ├── app_detection_service.dart  # Foreground app detection
│   │   └── fuzzy_search.dart       # Search algorithm
│   ├── screens/                    # UI screens
│   │   ├── home_screen.dart        # Main clipboard history UI
│   │   └── settings_screen.dart    # Settings dialog
│   ├── widgets/                    # Reusable UI components
│   │   ├── clipboard_item_tile.dart    # Item row widget
│   │   ├── groups_panel.dart           # Groups sidebar
│   │   └── sequence_mode_indicator.dart # Sequence mode UI
│   └── theme/                      # Theme configuration
│       └── app_theme.dart          # Light/dark themes
├── assets/                         # Images, icons
├── linux/                          # Linux platform code
├── macos/                          # macOS platform code
├── windows/                        # Windows platform code
└── test/                           # Unit tests
```

### Key Files to Know

- **main.dart** - App initialization, window setup, SQLite init
- **home_screen.dart** - Main UI, keyboard shortcuts, search
- **storage_service.dart** - All database operations
- **clipboard_service.dart** - Clipboard polling and monitoring

## Questions?

- **General questions:** [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
- **Security issues:** Email richesh.gupta@example.com (do not file public issues)

## Thank You!

Your contributions make CopyMan better for everyone. We appreciate your time and effort!

Happy coding! 🚀
