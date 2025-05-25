# GovGate App Firestore Database Schema

This document outlines the schema for the GovGate application's Firestore database.

## Collections

### users
Stores information about application users.

**Document ID**: Firebase Auth UID
```
{
  email: string,             // User email
  role: string,              // User role: "citizen", "government", or "advertiser"
  name: string,              // User's full name
  phone: string,             // Phone number
  nationalId: string,        // National ID number
  dateOfBirth: string,       // Date of birth in string format
  profession: string,        // User's profession
  gender: string,            // User's gender
  hometown: string,          // User's hometown
  createdAt: timestamp,      // Account creation date
  updatedAt: timestamp       // Last update date
}
```

### announcements
Stores government announcements.

**Document ID**: Auto-generated
```
{
  title: string,             // Announcement title
  content: string,           // Announcement content/body
  category: string,          // Category (Health, Education, etc.)
  imageUrl: string,          // Optional URL to announcement image
  authorId: string,          // UID of government user who created the announcement
  authorName: string,        // Name of the government official
  views: number,             // View counter
  createdAt: timestamp,      // Creation date
  updatedAt: timestamp       // Last update date
}

Sub-collection: comments
{
  text: string,              // Comment text
  isAnonymous: boolean,      // Whether comment is anonymous
  userId: string,            // UID of commenter (null if anonymous)
  userName: string,          // Name of commenter (or "Anonymous")
  createdAt: timestamp       // Comment date
}
```

### problem_reports
Stores citizen-reported problems.

**Document ID**: Auto-generated
```
{
  title: string,             // Problem title
  description: string,       // Problem description
  type: string,              // Problem type (Road damage, Water issues, etc.)
  location: geopoint,        // Geographic location of the problem
  images: array<string>,     // Array of image URLs
  status: string,            // Status (Pending, In Progress, Resolved, etc.)
  userId: string,            // UID of citizen who reported the problem
  userName: string,          // Name of reporting citizen
  createdAt: timestamp,      // Report date
  updatedAt: timestamp,      // Last update date
  assignedTo: string,        // Optional UID of government user assigned to the problem
  resolutionNotes: string,   // Optional notes on resolution
  resolutionDate: timestamp  // Optional date when problem was resolved
}
```

### government_messages
Stores messages from citizens to the government.

**Document ID**: Auto-generated
```
{
  subject: string,           // Message subject
  message: string,           // Message content
  type: string,              // Message type (Inquiry, Complaint, etc.)
  isAnonymous: boolean,      // Whether message is anonymous
  userId: string,            // UID of sender (null if anonymous)
  senderName: string,        // Name of sender (or "Anonymous")
  senderEmail: string,       // Email of sender (null if anonymous)
  status: string,            // Status (Unread, Read, Responded)
  createdAt: timestamp,      // Message date
  updatedAt: timestamp,      // Last update date
  response: string,          // Optional response from government
  responseDate: timestamp,   // Optional date of response
  respondedBy: string        // Optional name/ID of government user who responded
}
```

### polls
Stores government polls/surveys.

**Document ID**: Auto-generated
```
{
  title: string,             // Poll title
  description: string,       // Poll description
  options: map<string,int>,  // Map of options to vote counts: {"Option A": 10, "Option B": 5}
  createdBy: string,         // UID of government user who created the poll
  creatorName: string,       // Name of poll creator
  isAnonymous: boolean,      // Whether voting is anonymous
  createdAt: timestamp,      // Creation date
  expiryDate: timestamp,     // When poll closes
  totalVotes: number,        // Total number of votes
  isActive: boolean          // Whether poll is still active
}

Sub-collection: votes
{
  option: string,            // Selected option
  userId: string,            // UID of voter
  createdAt: timestamp       // Vote date
}
```

### emergency_contacts
Stores emergency contact information.

**Document ID**: Auto-generated
```
{
  name: string,              // Contact name
  number: string,            // Phone number
  category: string,          // Category (Police, Fire, Medical, etc.)
  description: string,       // Optional description
  createdAt: timestamp,      // Creation date
  updatedAt: timestamp       // Last update date
}
```

## Security Rules

Important security considerations:
1. Government users should only be able to create/edit announcements and polls
2. Citizens should only be able to create problem reports and send messages
3. Users should only be able to view and edit their own data
4. Poll votes should be protected based on anonymity settings

## Indexing

The following compound indexes should be created:

1. `problem_reports`: `userId` ASC, `createdAt` DESC
2. `government_messages`: `userId` ASC, `createdAt` DESC 
3. `polls`: `isActive` ASC, `createdAt` DESC

## Collection Group Queries

The following collection groups may be useful:
1. `comments` - For searching all comments across announcements 