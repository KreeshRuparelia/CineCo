# CineCo

An iOS app to help you keep track of movies and TV shows you've watched and/or want to watch.

## Features
- Search for content
- Track your watched content
- Manage a watchlist
- Discover new movies and TV shows through a swipable discover page.

## Setup Instructions

### Requirements
- Xcode 15.0+
- iOS 17.0+
- TMDB API Key

### Installation

1. **Clone the repository**
```bash
   git clone https://github.com/KreeshRuparelia/CineCo.git
   cd CineCo
```

2. **Configure TMDB API**
   - Go to [TMDB API Settings](https://www.themoviedb.org/settings/api)
   - Get an API Read Access Token
   - Rename `Config.swift.example` to `Config.swift`
   - Replace `<YOUR_TMDB_READ_ACCESS_TOKEN_HERE>` with your actual API read access token

3. **Make a Firebase project**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Download `GoogleService-Info.plist`
   - Add it to the root of the project
   - Enable Authentication (Email/Password and Anonymous)
   - Create a Firestore Database
   - Set up Firestore rules and indexes (see below)
  
4. **Firestore Rules**
   In the Firebase Console, navigate to Build > Firestore Database, and set this to be Rules:
   ```bash
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
         
        // Users collection - users can only read/write their own data
        match /users/{userId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
        
        // Watched collection - users can only access their own watched items
        match /watched/{watchedId} {
          allow read, write: if request.auth != null;
        }
        
        // Watchlist collection - users can only access their own watchlist items
        match /watchlist/{watchlistId} {
          allow read, write: if request.auth != null;
        }
        
        // Skipped collection - users can only add to their list of skipped itms
        match /skipped/{skippedId} {
          allow read, write: if request.auth != null;
        }
      }
    }
   ```
   
6. **Firestore Indexes**
   Create these three composite indexes in Firebase Console, at Build > Firestore Database > Indexes:
   - `watched`: userId (Ascending), contentType (Ascending), addedAt (Descending)
   - `watchlist`: userId (Ascending), contentType (Ascending), addedAt (Descending)
   - `skipped`: userId (Ascending), contentType (Ascending)

7. **Build and Run**
   - Open `CineCo.xcodeproj` in Xcode
   - Select your target device
   - Press Cmd + R to build and run
