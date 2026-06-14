# Project Plan

EchoFit: A health metric tracking application for Android and Windows (Flutter). Tracks weight, body fat, visceral fat, and waistline. Focuses on frictionless data entry via voice commands and voice entry. Synchronizes data using a Nextcloud server.

## Project Brief

# Project Brief: EchoFit

EchoFit is a health metric tracking application designed for effortless data logging and privacy-focused synchronization across multiple platforms. By leveraging voice-first interaction and secure Nextcloud integration, EchoFit ensures that maintaining a health diary is frictionless and user-controlled.

## Features
- **Voice-Driven Data Entry**: Record weight, body fat percentage, visceral fat, and waistline measurements instantly using natural language voice commands, eliminating manual typing.
- **Unified Health Dashboard**: A centralized view for both Android and Windows that provides a clear overview of body composition metrics and historical trends.
- **Secure Nextcloud Synchronization**: Cross-platform data persistence and backup using a user-owned Nextcloud server, ensuring complete data sovereignty and privacy.
- **Multi-Platform Adaptive Experience**: A responsive design that provides a tailored UI for Android mobile devices (handsets and foldables) and a native-feeling experience on Windows desktop.

## High-Level Technical Stack

- **Languages**: Dart (Primary for cross-platform logic), Kotlin (for Android-specific integrations)
- **UI Framework**: Flutter (supporting both Android and Windows targets)
- **State Management**: BLoC or Provider for state-driven UI logic.
- **Navigation & Adaptive Strategy**: Strictly use Flutter's state-driven routing and adaptive layout builders (inspired by modern Material 3 standards) for all layouts.
- **Core Dependencies**: `dio` or `http` for Nextcloud WebDAV API interaction, `speech_to_text` for natural language processing.

## Implementation Steps
**Total Duration:** 1h 26s

### Task_5_Flutter_Data_Layer_Sync: Implement the Flutter data layer using Drift or Sqflite for health metrics and a WebDAV client (using dio or http) for Nextcloud synchronization.
- **Status:** COMPLETED
- **Updates:** The coder_agent has successfully transitioned the project to Flutter and implemented the data layer using sqflite and dio for Nextcloud sync. Models for weight, body fat, visceral fat, and waistline are in place. Android build is successful.
- **Acceptance Criteria:**
  - SQLite database for metrics (weight, body fat, etc.) is functional
  - Nextcloud WebDAV integration for data sync is implemented using Flutter libraries
  - Successful Flutter build for Android
- **Duration:** 7m 7s

### Task_6_Voice_Integration_Flutter: Develop the voice command processing system using the speech_to_text package and implement a natural language parser for metric extraction.
- **Status:** COMPLETED
- **Updates:** The coder_agent has implemented the voice command processing using speech_to_text. A VoiceParser class handles metric extraction (weight, body fat, etc.) from spoken phrases and saves the data to the local DB. Permissions and UI feedback are also implemented. Build is successful.
- **Acceptance Criteria:**
  - speech_to_text correctly captures user voice input
  - Natural language parser extracts health data points (weight, body fat, etc.) from text
  - Voice entry flow saves data to local DB
- **Duration:** 10m 41s

### Task_7_Adaptive_UI_Flutter: Build the Health Dashboard and app navigation using Flutter's adaptive widgets (NavigationRail, NavigationBar, LayoutBuilder) and state-driven routing.
- **Status:** COMPLETED
- **Updates:** The coder_agent has implemented the adaptive UI using NavigationRail and NavigationBar. LayoutBuilder handles different screen sizes. A Health Dashboard with fl_chart for trends and MetricCards for metrics is implemented. Riverpod is used for state management. Build is successful.
- **Acceptance Criteria:**
  - Adaptive layouts implemented using NavigationRail and LayoutBuilder for different screen sizes
  - State-driven routing manages transitions between Dashboard and Data Entry
  - Dashboard displays historical trends and latest metrics
- **Duration:** 2m 9s

### Task_8_Final_Polish_and_Verification: Apply a vibrant Material 3 theme, generate an adaptive app icon, and perform final application verification across targets.
- **Status:** COMPLETED
- **Updates:** The critic_agent has verified the final implementation. The application now includes a fully functional Nextcloud Settings UI, dynamic icon brightness for dark mode, and automatic sync triggers on startup and data entry. The adaptive UI and icons are correctly implemented. The app is stable and follows Material 3 guidelines.
- **Acceptance Criteria:**
  - Vibrant Material 3 theme and adaptive app icon implemented
  - Critic agent verifies application stability (no crashes) and alignment with user requirements
  - Build pass, all existing tests pass, and app does not crash
- **Duration:** 40m 29s

