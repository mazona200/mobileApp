# GovGate Database Setup Guide

This guide will help you set up the Firebase database for the GovGate mobile application.

## Prerequisites

1. A Firebase project created in the [Firebase Console](https://console.firebase.google.com/)
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. Node.js and npm installed

## Setup Instructions

### 1. Connect Your App to Firebase

1. In the Firebase Console, add a new app (Android/iOS depending on your target platform)
2. Follow the setup instructions to download the config files:
   - For Android: `google-services.json` (place in `android/app/`)
   - For iOS: `GoogleService-Info.plist` (place in the appropriate iOS directory)

### 2. Enable Firebase Services

In the Firebase Console, enable the following services:

1. **Authentication**
   - Enable Email/Password authentication method
   - Optionally enable Google Sign-In for easier authentication

2. **Firestore Database**
   - Create a Firestore database in production mode
   - Choose a location closest to your target audience

3. **Storage**
   - Enable Firebase Storage for storing images and other files
   - Set appropriate CORS configuration

### 3. Deploy Security Rules

Deploy the Firestore security rules from the `firestore.rules` file:

```bash
firebase deploy --only firestore:rules
```

### 4. Create Firestore Indexes

Create the following composite indexes to optimize queries:

1. `problem_reports` collection:
   - Fields: `userId` (Ascending), `createdAt` (Descending)

2. `government_messages` collection:
   - Fields: `userId` (Ascending), `createdAt` (Descending)

3. `polls` collection:
   - Fields: `isActive` (Ascending), `createdAt` (Descending)

You can create these indexes either through the Firebase Console or by deploying an `firestore.indexes.json` file.

### 5. Seed Initial Data (Optional)

To seed some initial data into your database:

1. Generate a service account key file from Firebase Console:
   - Go to Project Settings > Service Accounts
   - Generate a new private key and save it as `serviceAccountKey.json` in the project root
   - **Important:** Do not commit this file to git! Add it to your `.gitignore`.

2. Run the seed script:
```bash
node scripts/seed_database.js
```

## Database Schema

The application uses the following collections:

- `users`: User accounts and profile information
- `announcements`: Government announcements with subcollection for comments
- `problem_reports`: Citizen-reported problems
- `government_messages`: Messages from citizens to government
- `polls`: Government polls with subcollection for user votes
- `emergency_contacts`: Emergency contact information

See `docs/DATABASE_SCHEMA.md` for the detailed schema structure.

## Security Considerations

1. The Firestore security rules enforce role-based access control:
   - Only government users can create announcements and polls
   - Only citizens can report problems and send messages
   - Users can only view and edit their own data

2. Anonymous options for comments and messages are implemented in a way that protects user identity while preventing abuse.

3. Poll votes have privacy protections when anonymous voting is selected.

## Best Practices

1. Use the `DatabaseService` methods for all database operations.

2. Use `FieldValue.serverTimestamp()` for timestamps to ensure consistency.

3. Handle Firebase errors gracefully using try/catch blocks.

4. Use transaction operations when updating counters or critical data that could have race conditions.

5. Implement proper error handling and offline capabilities in the app.

## Troubleshooting

- If you encounter permission errors, check the Firestore security rules in the Firebase Console.
- For query errors, ensure you have created the necessary indexes.
- For authentication issues, verify your configuration in `firebase_options.dart`.

## Further Information

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Data Modeling Guide](https://firebase.google.com/docs/firestore/manage-data/structure-data)
- [Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started) 