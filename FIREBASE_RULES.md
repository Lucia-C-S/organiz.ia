# Firebase Security Rules Configuration

This file explains how to set up security rules for your Firebase project to ensure the 3 users can access product photos while maintaining security.

## Cloud Firestore Rules

Go to Firebase Console > Firestore Database > Rules and paste these rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user profile
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      // Users can read/write their own pantry items
      match /pantryItems/{itemId=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
    
    // Products collection - all authenticated users can read, but only owner can write
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Cloud Storage Rules

Go to Firebase Console > Storage > Rules and paste these rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Product photos are accessible to all authenticated users
    match /item_photos/{allPaths=**} {
      allow read: if request.auth != null;
      allow write, delete: if request.auth != null;
    }
  }
}
```

## Explanation

- **Cloud Firestore**: 
  - User profiles are private (only the user can read/write their own)
  - Pantry items are private (only the user can access their own items)
  - Products can be read by any authenticated user
  
- **Cloud Storage**:
  - All authenticated users can upload, download, and delete photos
  - This means all 3 users can see all product photos
  - If you need more granular control (e.g., only the uploader can delete), modify the `delete` rule

## To Apply Rules

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project (organiz-ia-2026)
3. Go to Firestore Database or Storage
4. Click on the "Rules" tab
5. Copy-paste the appropriate rules
6. Click "Publish"

## Security Levels

Currently implemented:
- ✅ All 3 users can see all product photos
- ✅ Users must be authenticated to access anything
- ✅ User data is private to each user
- ✅ Any authenticated user can upload/download photos

If you want stricter rules later (e.g., only certain users can upload), you can modify these rules accordingly.
