# BookShelf

BookShelf is a Flutter app for managing a private, searchable bookshelf. It uses
Firebase Authentication (Email/Password) and Cloud Firestore.

## Configure Firebase

1. Create or select your Firebase project and register the Android app with
   application ID `com.example.bookshelf`.
2. Enable **Authentication → Email/Password** and create a Firestore database.
3. Replace the client configuration in `lib/firebase_options.dart` and
   `android/app/google-services.json` with the configuration for your Firebase
   project. These are client configuration files; do not add service-account
   credentials to the app.
4. Publish the rules in `firestore.rules`:

   ```sh
   firebase deploy --only firestore:rules
   ```

5. Create a test account in Firebase Authentication before trying to log in.

The Firestore collection is `books`. Queries are scoped to the current Firebase
user, and the rules validate ownership and the required book fields. The app
uses a deterministic document ID derived from the signed-in user and the
case-insensitive title/author pair. This prevents duplicate pairs created
through the app, including concurrent submissions using the same ID. Firestore
Security Rules cannot scan a collection to detect duplicates written using an
arbitrary document ID; do not use arbitrary IDs when creating books outside the
app.

## Run and test

```sh
flutter pub get
flutter run
flutter test
```

The project targets Android. After configuring Firebase, build a release APK
with `flutter build apk --release`.
