# CrewCraft AI

> Smart team formation and collaboration assistant built with Flutter, Firebase, and ML powered recommendations.

CrewCraft AI (formerly CollabVerse) helps makers of all skill levels discover compatible teammates, propose projects, and coordinate delivery through realtime collaboration tooling.

## Contents
1. [Highlights](#highlights)
2. [System Overview](#system-overview)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Local Setup](#local-setup)
6. [Firebase Configuration](#firebase-configuration)
7. [Running & Deployment](#running--deployment)
8. [Core Workflows](#core-workflows)
9. [Data Model](#data-model)
10. [Testing & Quality](#testing--quality)
11. [Troubleshooting](#troubleshooting)
12. [Contributing](#contributing)
13. [License](#license)

## Highlights
- Skill aware discovery ranks open teams by overlap with the current users declared skills.
- Guided team creation captures team name, project name, target size, and required skills with smart defaults.
- Pending requests workflow lets leaders approve candidates and rename teams before activation.
- Team dashboards surface chat, task allocation, activity logs, and notifications through realtime Firestore streams.
- Cross platform branding keeps the CrewCraft AI identity aligned on Android, iOS, web, and desktop.
- Modular services and providers make it easy to extend features without touching UI layers.

## System Overview
```
+---------------------------------------------------------+
| Presentation Layer (Flutter widgets)                    |
| - Auth screens, home tabs, team dashboards              |
| - Shared widgets such as CrewCraftLogo and buttons      |
+---------------------------------------------------------+
                     ||
+---------------------------------------------------------+
| Services and Providers (business logic)                 |
| - AuthProvider, TeamProvider, ProfileProvider           |
| - AuthService, JoinRequestService, ChatService, more    |
| - ML API service for similarity scoring                 |
+---------------------------------------------------------+
                     ||
+---------------------------------------------------------+
| Data Layer (Firebase and REST)                          |
| - Firebase Auth, Cloud Firestore, Cloud Storage         |
| - Optional external ML endpoints over HTTPS             |
+---------------------------------------------------------+
```

## Tech Stack
- Flutter 3.x and Dart for cross platform delivery
- Firebase Authentication for identity management
- Cloud Firestore for realtime data and offline caching
- Cloud Storage for user assets (avatars, attachments)
- Provider and ChangeNotifier for client side state
- REST integrations through `lib/services/ml_api_service.dart`

## Project Structure
```
lib/
  main.dart                 # Entry point, routing, Firebase init
  firebase_options.dart     # Generated Firebase configuration
  models/                   # Firestore data models
  providers/                # App wide state (auth, profile, team)
  services/                 # Firestore and REST access layers
  screens/                  # Feature UIs (auth, home, teams, etc.)
  utils/                    # Constants and helpers (skill similarity)
  widgets/                  # Reusable UI components (logo, buttons)
```

Platform folders (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) contain Flutter scaffolding plus CrewCraft AI branding updates (names, icons, metadata).

## Local Setup
1. Clone the repository.
   ```bash
   git clone https://github.com/avikagupta03/CollabVerse.git
   cd CollabVerse
   ```
2. Install Flutter dependencies.
   ```bash
   flutter pub get
   ```
3. Configure Firebase for the platforms you plan to run (see below).
4. Verify tooling.
   ```bash
   flutter doctor
   ```
5. Launch the app on a device or emulator.
   ```bash
   flutter run -d chrome
   flutter run -d windows
   flutter run
   ```

## Firebase Configuration
CrewCraft AI expects a Firebase project with email and password authentication plus Cloud Firestore.

1. Create a Firebase project and register the Android, iOS, web, and desktop targets you need.
2. Download configuration files and place them accordingly:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`
   - `web/firebase-messaging-sw.js` if messaging is enabled
3. Run `flutterfire configure` whenever project identifiers change to regenerate `lib/firebase_options.dart`.
4. Adjust Firestore security rules to permit authenticated reads and writes for development.

## Running & Deployment
- Use `flutter run` for iterative development with hot reload (press `r` in the console).
- Build release packages with:
  - `flutter build apk` or `flutter build appbundle` for Android
  - `flutter build ios` for iOS
  - `flutter build web` for static hosting
  - `flutter build windows|macos|linux` for desktop
- Update launcher icons and splash screens before publishing to app stores.

## Core Workflows
- Onboarding: users register, complete a profile, and declare skills, interests, and experience.
- Discover: the Discover tab streams team requests, computes similarity scores, and shows leader and project context with live member counts.
- Join requests: candidates submit join requests that leaders manage in `PendingRequestsPage`, including final naming for teams and projects.
- Team collaboration: `MyTeamsPage` links to dashboards that expose chat, task allocation, notifications, and activity feeds.
- Notifications: services push structured alerts for membership changes, chat messages, and task updates.

## Data Model
| Collection     | Purpose                               | Key fields |
|----------------|---------------------------------------|------------|
| `users`        | Profile data for each member          | `displayName`, `skills[]`, `interests[]`, `experience`, `avatarUrl` |
| `teamRequests` | Open opportunities published by leads | `team_name`, `project_name`, `required_skills[]`, `team_size`, `status`, `creator_id`, `creator_name`, `created_at` |
| `teams`        | Active teams after approval           | `members[]`, `leader_id`, `team_name`, `project_name`, `activity_summary` |
| `joinRequests` | Pending membership decisions          | `teamId`, `applicantId`, `status`, `submitted_at`, `notes` |
| `messages`     | Real time team communication          | `teamId`, `senderId`, `content`, `timestamp` |
| `notifications`| User alerts and reminders             | `userId`, `type`, `payload`, `created_at`, `read` |

Similarity scores are calculated in `lib/utils/skill_similarity_calculator.dart` by normalizing skill strings and measuring overlap.

## Testing & Quality
- Static analysis: `flutter analyze`
- Formatting: `dart format lib`
- Tests: `flutter test`
- Recommended CI gates: formatting, analysis, and targeted tests before merge

## Troubleshooting
- Enable Developer Mode on Windows before running desktop builds (Settings > Privacy and Security > For Developers).
- Guard asynchronous callbacks with `if (!mounted) return;` in stateful widgets to avoid setState after dispose warnings.
- Rerun `flutterfire configure` if Firebase initialization fails due to changed project identifiers.
- Configure CORS for any custom ML endpoints used by the web build.

## Contributing
1. Fork the repository and create a feature branch.
2. Follow the provider and service architecture already in place.
3. Run `flutter analyze` and `dart format lib` before committing.
4. Document notable changes in this README or additional guides.
5. Open a pull request with context, screenshots, and test evidence where helpful.

## License
This project is distributed under the [MIT License](LICENSE).

CrewCraft AI brings together the right teammates for the right projects. Build boldly and collaborate faster.
