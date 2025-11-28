# 🚀 CollabVerse - Team Formation AI Platform

> **Smart team matching and collaboration platform powered by AI**

A Flutter + Firebase application that helps developers find and form teams based on skill compatibility, using ML-powered recommendations.

---

## 📋 Table of Contents

1. [Features](#-features)
2. [Architecture Overview](#-architecture-overview)
3. [Project Structure](#-project-structure)
4. [Getting Started](#-getting-started)
5. [How It Works](#-how-it-works)
6. [Screens Guide](#-screens-guide)
7. [Core Features](#-core-features)
8. [Firebase Data Flow](#-firebase-data-flow)
9. [Skill Matching Algorithm](#-skill-matching-algorithm)
10. [Dependencies](#-dependencies)
11. [Development Guide](#-development-guide)

---

## ✨ Features

### ✅ **User Management**

- Firebase Authentication (Login/Register)
- User profiles with skills, interests, and experience
- Profile editing and updates
- Real-time profile synchronization

### ✅ **Team Discovery**

- Browse all team requests
- Search by skills or project description
- **Skill-based recommendations** - requests sorted by compatibility with user's tech stack
- Real-time team request updates
- Team captain information display

### ✅ **Team Request Creation**

- Create new team requests with:
  - Required skills (comma-separated)
  - Team size (minimum 2 members)
  - Project description
- Automatic ML-based team suggestions
- Status tracking (Open, Hiring, Active, Completed)

### ✅ **Team Management**

- Join teams from requests
- View joined teams
- Team dashboard with:
  - Kanban task board
  - Real-time chat
  - Activity feed
  - Notifications

### ✅ **Matching & Recommendations**

- **Skill similarity scoring** (0-100%)
- AI-powered member suggestions based on skills
- Team composition analysis
- Experience matching
- Interest-based compatibility

### ✅ **Real-Time Collaboration**

- Team chat with real-time messaging
- Activity logging (created, updated, joined)
- Notifications for team activities
- Role-based permissions (Admin, Leader, Member)

---

## 🏗️ Architecture Overview

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (UI)                    │
│  • HomeScreen (4 tabs)                                  │
│  • DiscoverPage (Browse & Filter)                       │
│  • CreateRequestPage (Form)                             │
│  • MyTeamsPage (Team List)                              │
│  • ProfileScreen (User Profile)                         │
│  • TeamDashboard (Team Management)                      │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│           BUSINESS LOGIC LAYER (Services)               │
│  Core Services:          Feature Services:              │
│  • AuthService          • ChatService                   │
│  • ProfileService       • ActivityService               │
│  • TeamRequestService   • NotificationService           │
│  • TeamMatcherService   • PermissionService             │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│         DATA LAYER (Firebase & Local Models)            │
│  • Firebase Auth                                        │
│  • Cloud Firestore (7 collections)                      │
│  • Real-time Streams                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
collabverse/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/                            # Data models
│   │   ├── user_profile.dart
│   │   ├── team_model.dart
│   │   ├── team_request_model.dart
│   │   └── activity_model.dart
│   ├── services/                          # Business logic
│   │   ├── auth_service.dart              # Authentication
│   │   ├── profile_service.dart           # User profiles
│   │   ├── team_request_service.dart      # Team request CRUD
│   │   ├── team_matcher_service.dart      # ML matching
│   │   ├── chat_service.dart              # Messaging
│   │   ├── activity_service.dart          # Activity tracking
│   │   ├── notification_service.dart      # Notifications
│   │   └── permission_service.dart        # Role-based access
│   ├── screens/                           # UI Screens
│   │   ├── auth/                          # Auth screens
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/                          # Main app
│   │   │   ├── home_screen.dart
│   │   │   └── discover_page.dart         # Skill-based team browsing
│   │   ├── team_request/
│   │   │   └── create_request_page.dart
│   │   ├── teams/
│   │   │   └── my_teams_page.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   └── team_dashboard/                # Team workspace
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── constants.dart
│   │   └── skill_similarity_calculator.dart  # Matching algorithm
│   └── widgets/
│       └── reusable widgets
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 2.17+
- Firebase Account
- Git

### Installation

```bash
# 1. Clone repo
git clone <url>
cd collabverse

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# - Download google-services.json to android/app/
# - Download GoogleService-Info.plist to ios/Runner/

# 4. Run
flutter run
```

### First Time

1. Register account
2. Fill profile with skills (e.g., "Flutter, Dart, Firebase")
3. Browse Discover page (sorted by skill match)
4. Create team request
5. Join teams

---

## 🔄 How It Works - Skill Matching Flow

```
1. User Profile Setup
   └─ Enter skills: "Flutter, Dart, Firebase"
   └─ Saved to Firestore users collection

2. Team Request Created
   └─ Requires: "Flutter, Java, Docker"
   └─ Saved to Firestore teamRequests collection
   └─ creator_name: "John Doe"

3. Discover Page Loads
   └─ Gets current user's skills
   └─ Loads all team requests
   └─ For each request:
      • Calculate: commonSkills / requiredSkills × 100
      • Flutter = match ✅ (100%)
      • Java = no match ❌ (33%)
      • Docker = no match ❌ (33%)
      • Result: 1/3 × 100 = 33%
   └─ Sort by percentage (highest first)
   └─ Display with creator name

4. User Sees
   └─ Request at correct position based on skill match
   └─ Shows "Led by John Doe"
   └─ Matching skills in green
   └─ Non-matching in purple
```

---

## 📱 Key Screens Explained

### DiscoverPage (Tab 1)

- **Search** - Filter by skill/description
- **Real-time list** - Team requests sorted by skill match %
- **Cards show**:
  - Description
  - **"Led by [Team Captain Name]"**
  - Required skills
  - Match percentage & progress bar
  - Color-coded status

### CreateRequestPage (Tab 2)

- Enter required skills (comma-separated)
- Enter team size (minimum 2)
- Enter project description
- Automatically saves creator info

### MyTeamsPage (Tab 3)

- List of joined teams
- Click to open team dashboard

### ProfileScreen (Tab 4)

- Edit your profile
- **Update skills** - Critical for matching!

---

## 🧮 Skill Matching Algorithm

```dart
Match % = (Your Skills ∩ Required Skills) / Required Skills × 100

Example:
Your skills:     [Java, Python, Firebase, React]
Required skills: [Java, Python, Django]
Common:          [Java, Python] = 2 skills
Match:           2 / 3 × 100 = 66.67%
Display:         "67% Match" (Amber color)
```

**Sorting**:

- Highest % first (80-100% = Green)
- Then 50-79% (Amber)
- Then 1-49% (Orange)
- Then 0% (Grey)

---

## 🔥 Firebase Collections

```
users/{userId}
├─ name, email, bio
├─ skills: [array]        ← Used for matching
├─ interests, experience
└─ timestamp

teamRequests/{requestId}
├─ description
├─ required_skills: [array]  ← Matched against user skills
├─ team_size (≥ 2)
├─ status (Open|Hiring|Active|Completed)
├─ creator_id              ← Who created
├─ creator_name            ← Display name ("Led by...")
├─ suggested_teams: [array]
└─ created_at, updated_at

teams/{teamId}
├─ name, project_name
├─ members: [array]
├─ leader_id
├─ skills, deadline
└─ created_at

messages/{id}          ← Real-time chat
activityLogs/{id}      ← Activity tracking
notifications/{id}     ← Notifications
```

---

## 👨‍💻 Development

### Adding Skills to User

```dart
// In profile_screen.dart
skillsCtrl.text = 'Flutter, Dart, Firebase';
// Save to users/{uid}.skills
```

### Creating Request

```dart
// In create_request_page.dart
// Automatically saves:
// - creator_id (your UID)
// - creator_name (your name)
// - required_skills
// - team_size
```

### Skill Matching Logic

```dart
// In skill_similarity_calculator.dart
static double calculateSimilarity(
  List<String> userSkills,
  List<String> requiredSkills,
) {
  // Normalize to lowercase
  // Count exact matches
  // Return percentage (0-100)
}
```

---

## ✅ Verification Checklist

- ✅ User can register & login
- ✅ Profile saves skills correctly
- ✅ Team request shows creator name
- ✅ Discover page sorts by skill match %
- ✅ Highest matching requests appear first
- ✅ Matching skills highlighted in green
- ✅ Single "View & Join" button (no duplicates)
- ✅ Real-time updates without refresh
- ✅ Zero compilation errors
- ✅ Minimum team size = 2

---

## 📖 Documentation Files

- `PROJECT_CONNECTIVITY.md` - Architecture details
- `INTEGRATION_STATUS.md` - Integration verification
- `IMPLEMENTATION.md` - Implementation guide
- `QUICK_REFERENCE.md` - Quick lookup
- `CLEANUP_AND_OPTIMIZATION.md` - Recent improvements
- `PROJECT_STATUS_FINAL.md` - Project completion

---

**Ready to build teams with AI matching! 🚀**
