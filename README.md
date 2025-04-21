# VoiceNotes - Flutter Voice Note Taking App

A simple yet powerful voice note-taking application built with Flutter. Record your thoughts, meetings, or memos easily, transcribe them to text, and manage your notes effectively.

## Description

VoiceNotes aims to provide a seamless experience for capturing audio notes on the go. It allows users to record audio, store it locally, optionally transcribe the audio to text using device capabilities, and export notes. The app integrates unobtrusive ads using AdMob to support its development.

## Features

*   **Voice Recording:** High-quality audio recording.
*   **Note Management:** Create, view, edit, and delete voice notes.
*   **Transcription:** (Locally processed) Transcribe recorded audio to text for easy reading and searching.
*   **Note Export:** Export notes with transcribed text to PDF and DOCX formats.
*   **Local Storage:** All notes and transcriptions are stored securely on the user's device.
*   **AdMob Integration:** Interstitial ads are shown after certain actions (e.g., saving, transcribing, exporting).
*   **Customizable Splash Screen:** Features the app's logo and branding colors.
*   **Platform Support:** Android (iOS can be targeted with Flutter).

## Tech Stack

*   **Framework:** Flutter (v3.x - *Update if different*)
*   **Language:** Dart
*   **State Management:** Riverpod
*   **Database:** Drift (based on Moor) with SQLite (using `sqlite3_flutter_libs`)
*   **Audio Recording:** `record` package
*   **Transcription:** `speech_to_text` package
*   **UI:** Flutter Material Widgets, `google_fonts`, `flutter_animate`, `lottie`, `font_awesome_flutter`
*   **File Handling/Export:** `path_provider`, `share_plus`, `pdf`, `docx_template`
*   **Advertising:** `google_mobile_ads` (AdMob)
*   **Splash Screen:** `flutter_native_splash`
*   **Firebase:** Firebase Analytics (integrated via `firebase_core`, `firebase_analytics`)
*   **Build Tool:** Gradle (for Android)

## Getting Started

You can follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   Flutter SDK: Make sure you have the Flutter SDK installed. See the [Flutter installation guide](https://flutter.dev/docs/get-started/install).
*   Android Studio (with Android SDK and Command-line Tools) or VS Code (with Flutter extensions).
*   An Android Emulator or a physical Android device.
*   Node.js and npm (if you need to manage Firebase CLI).
*   Firebase CLI (Optional, for deploying privacy policy): `npm install -g firebase-tools`

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd voicenotes 
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase (Android):**
    *   Place your `google-services.json` file (downloaded from your Firebase project console) into the `android/app/` directory.
4.  **Configure AdMob (Android):**
    *   Ensure your AdMob App ID is correctly placed as a `<meta-data>` tag within the `<application>` tag in `android/app/src/main/AndroidManifest.xml`.
5.  **Run the app:**
    ```bash
    flutter run
    ```

## Building for Release (Android)

1.  **Create an Upload Keystore:**
    *   If you haven't already, generate a signing key using `keytool`. Navigate to `android/app` and run:
        ```bash
        keytool -genkey -v -keystore <keystore-name>.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <your-alias-name>
        ```
    *   **IMPORTANT:** Back up this keystore file and securely record its passwords!
2.  **Configure Keystore Credentials:**
    *   Create a file named `key.properties` in the `android` directory (or `android/app` depending on your configuration in `build.gradle`).
    *   Add the following lines, replacing placeholders with your actual credentials:
        ```properties
        storePassword=<your-keystore-password>
        keyPassword=<your-key-password>
        keyAlias=<your-alias-name>
        storeFile <relative-path/to/your/keystore-name.jks> 
        ```
        *(Ensure `storeFile` path is correct relative to the `key.properties` file)*.
    *   **Add `key.properties` to your `.gitignore` file!** Do not commit sensitive credentials.
3.  **Ensure `android/app/build.gradle` is configured:**
    *   The file should contain logic to read `key.properties` and set up `signingConfigs.release`.
    *   `minifyEnabled` and `shrinkResources` should ideally be set to `true` under `buildTypes.release`.
4.  **Update App Version:**
    *   Increment the `version` code (e.g., `1.0.0+1` to `1.0.1+2`) in `pubspec.yaml`.
5.  **Clean Project:**
    ```bash
    flutter clean
    ```
6.  **Build App Bundle (.aab):**
    ```bash
    flutter build appbundle
    ```
    *   The output `.aab` file will be located in `build/app/outputs/bundle/release/`. This is the file you upload to the Google Play Store.
7.  **Build APK (Optional):**
    ```bash
    flutter build apk-- release
    ```
    *   The output `.apk` file will be in `build/app/outputs/flutter-apk/`.

## Privacy Policy

App stores require a privacy policy. The `/web` directory includes a template [privacy_policy.html](web/privacy_policy.html).
1.  **Customize:** Edit `web/privacy_policy.html` with your specific details (developer name, contact email, effective date) and ensure it accurately reflects your data handling practices.
2.  **Deploy:** Host this file (e.g., using Firebase Hosting).
    *   `firebase login` (if needed, run in your terminal)
    *   `firebase init hosting` (configure for the `web` directory)
    *   `firebase deploy --only hosting`
3.  **URL:** Use the generated URL (e.g., `https://<your-project-id>.web.app/privacy_policy.html`) in the Google Play Console.

## Folder Structure (Simplified)

```
voicenotes/
├── android/          # Android specific files
├── ios/              # iOS-specific files (if targeting iOS)
├── lib/              # Dart code
│   ├── core/         # Core utilities, constants, themes
│   ├── features/     # Feature-specific modules (e.g., notes, auth, settings)
│   │   ├── notes/    # Notes feature screens, providers, models
│   │   └── ...       # Other features
│   ├── models/       # Data models
│   ├── services/     # Business logic services (e.g., AdMobService, TranscriptionService)
│   ├── utils/        # Utility functions
│   └── main.dart     # App entry point
├── assets/           # App assets (images, fonts, Lottie files)
│   ├── fonts/
│   ├── images/
│   └── lottie/
├── web/              # Web files (for privacy policy)
│   └── privacy_policy.html
├── test/             # Unit and widget tests
├── pubspec.yaml      # Project dependencies and metadata
├── README.md         # This file
└── ...               # Other configuration files (e.g., .gitignore, analysis_options.yaml)

