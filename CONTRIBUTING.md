# Contributing to ServMarket

Thank you for your interest in contributing to ServMarket! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Git Workflow](#git-workflow)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Code Review Process](#code-review-process)

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (2.17 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account
- Git

### Initial Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/servmarket.git
   cd servmarket
   ```

3. Install dependencies:
   ```bash
   cd servmarket
   flutter pub get
   ```

4. Set up Firebase:
   - Contact the team lead for Firebase project access
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories (never commit these files)
   - See `.env.example` for required environment variables

## Development Setup

### Firebase Configuration

**Important:** Firebase configuration files are sensitive and must never be committed to Git.

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

These files are listed in `.gitignore`. Obtain them from the team lead through a secure channel.

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload (while app is running)
# Press 'r' in the terminal
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Project Structure

```
servmarket/
├── lib/
│   ├── core/              # Theme, constants, error handling, configuration
│   ├── models/            # Data models (UserProfile, ProviderProfile, Message, etc.)
│   ├── services/          # Business logic and API calls
│   ├── repositories/      # Data access layer (Firestore abstraction)
│   ├── providers/         # State management (Provider pattern)
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable UI components
│   ├── utils/             # Utility functions
│   └── main.dart          # App entry point
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
└── linux/                 # Linux-specific code
```

### Architecture Guidelines

- **Models**: Pure Dart classes with `fromJson`/`toJson` methods
- **Services**: Handle business logic and external API calls
- **Repositories**: Abstract data access, isolate Firestore queries
- **Providers**: Manage app state using the Provider package
- **Screens**: UI components, should be stateless where possible
- **Widgets**: Reusable UI components

## Coding Standards

### Dart/Flutter Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues:
  ```bash
  flutter analyze
  ```
- Format code with:
  ```bash
  dart format .
  ```

### Naming Conventions

- **Files**: `snake_case.dart` (e.g., `user_profile.dart`)
- **Classes**: `PascalCase` (e.g., `UserProfile`)
- **Variables/Functions**: `camelCase` (e.g., `userName`, `getUserData()`)
- **Constants**: `lowerCamelCase` or `SCREAMING_SNAKE_CASE` for globals
- **Private members**: Prefix with `_` (e.g., `_privateMethod`)

### Code Organization

- Order imports: dart → flutter → third-party → local
- Group related functions together
- Add documentation comments for public APIs
- Keep functions focused and under 50 lines when possible

### State Management

- Use the Provider package for state management
- Call `notifyListeners()` wrapped in `addPostFrameCallback` to avoid build-phase errors:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    notifyListeners();
  });
  ```

### Error Handling

- Always handle potential errors with try-catch blocks
- Provide user-friendly error messages in French
- Log technical errors for debugging
- Never expose sensitive information in error messages

## Git Workflow

### Branch Naming

Use the following branch naming convention:

- `feature/issue-number-description` (e.g., `feature/14-geolocation-permission`)
- `fix/issue-number-description` (e.g., `fix/7-firestore-permission-error`)
- `hotfix/description` (for urgent fixes)

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Example:**
```
feat(messaging): add real-time conversation updates

Implement real-time message synchronization using Firestore streams.
Add unread message indicator in conversation list.

Closes #27
```

### Workflow

1. Create a new branch from `main`:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/14-description
   ```

2. Make your changes and commit them

3. Push your branch:
   ```bash
   git push origin feature/14-description
   ```

4. Create a Pull Request on GitHub

## Submitting Changes

### Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows the project's coding standards
- [ ] Code is formatted (`dart format .`)
- [ ] Code passes analysis (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] Commits follow the conventional commit format
- [ ] PR description references related issue(s)
- [ ] No sensitive files are included (check `.gitignore`)
- [ ] Firebase config files are NOT committed

### Pull Request Template

```markdown
## Description
Brief description of changes

## Related Issue
Closes #<issue-number>

## Changes
- Change 1
- Change 2

## Testing
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Manual testing steps

## Screenshots (if applicable)
Add screenshots for UI changes
```

## Reporting Issues

### Bug Reports

When reporting a bug, include:

- **Title**: Clear and descriptive
- **Description**: Detailed explanation of the bug
- **Steps to reproduce**: Minimal reproduction steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: OS, Flutter version, device/emulator details
- **Logs**: Relevant error logs

### Feature Requests

When requesting a feature:

- **Title**: Clear and descriptive
- **Description**: Detailed explanation of the feature
- **Use case**: Why this feature is needed
- **Alternatives**: Any alternative solutions considered

## Code Review Process

### Review Guidelines

- Be constructive and respectful
- Focus on the code, not the person
- Provide clear explanations for suggestions
- Acknowledge good work

### Response Time

- Aim to review PRs within 48 hours
- Respond to review comments within 24 hours

### Approval Process

- At least one approval from a team member required
- All CI checks must pass
- No unresolved conflicts with `main`

## Security

### Sensitive Data

- Never commit API keys, passwords, or secrets
- Use environment variables for sensitive configuration
- Check `.gitignore` before committing
- Report security vulnerabilities privately to the team lead

### Firebase Security

- Firestore security rules must be tested before deployment
- Never use `service_role` keys in the client app
- Enable RLS (Row Level Security) for all Supabase tables

## Questions?

For questions about contributing, contact the team lead or open an issue with the `question` label.

---

Thank you for contributing to ServMarket! 🚀
