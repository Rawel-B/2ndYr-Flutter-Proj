# FlutterTrello

FlutterTrello is a project collaboration app built with Flutter. It gives teams a simple workspace for creating projects, inviting members, assigning tasks, and tracking progress through a Kanban-style board.

The app currently runs with seeded demo data and can also attempt to connect to Firebase when configuration is available.

## Features

- Email sign in and sign up flow
- Project dashboard with progress tracking
- Kanban and list views for project tasks
- Task creation, assignment, comments, and file attachments
- Member invitations and project manager assignment
- Activity feed and notifications
- Admin view for managing the workspace
- Responsive layout for mobile and wider screens

## Tech Stack

- Flutter
- Dart
- Provider for state management
- Firebase Core, Firebase Auth, and Cloud Firestore support
- File Picker and Image Picker packages

## Getting Started

Clone the project, install dependencies, and run it with Flutter:

```bash
flutter pub get
flutter run
```

The demo login fields are pre-filled in the app, so you can sign in quickly and explore the workspace.

## Notes

This project is still in development. Some data is handled through the local demo repository while Firebase support is being prepared for a more complete backend setup.
