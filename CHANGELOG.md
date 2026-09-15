# Changelog

All notable changes to the ServMarket project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Messaging system with real-time conversations
- Service request management for clients and providers
- Provider home screen with request management
- Client requests screen for tracking service requests
- Service request detail screen
- Conversation screen with message history
- Conversations list screen
- Onboarding illustrations and improved UX
- App logo widget
- Ticket badge clipper widget
- Geolocation service enhancements
- Messaging service with Firestore integration
- Conversation and message models
- Service request model
- Android permissions for geolocation and messaging

### Changed
- Improved theme.dart with better color schemes
- Enhanced auth_screen.dart with better error handling
- Refactored list_screen.dart for better performance
- Updated map_screen.dart with improved marker handling
- Enhanced provider_detail_screen.dart with better UI
- Improved provider_form_screen.dart with validation
- Updated onboarding_screen.dart with better flow
- Updated home_screen.dart with navigation improvements
- Enhanced provider_home_screen.dart with request management

### Fixed
- Fixed setState() or markNeedsBuild() called during build error in MessagingProvider
- Wrapped all notifyListeners() calls with addPostFrameCallback to prevent build-phase state updates

### Known Issues
- Firestore permission errors for conversations collection (requires security rules update)
- Missing Firestore index for service_requests queries
- Google Play Services warnings on some devices

## [0.2.0] - 2026-09-12

### Added
- Search provider with geolocation support
- Geohash-based spatial search
- Distance filtering with Haversine formula
- Provider home screen
- Enhanced geolocation service
- Search provider state management

### Changed
- Refactored list_screen.dart for better search integration
- Updated map_screen.dart with geolocation features
- Enhanced provider_form_screen.dart with location fields
- Improved provider_profile.dart model

## [0.1.0] - 2026-09-10

### Added
- Initial project setup
- Firebase Authentication integration
- Provider profile management
- Basic provider form
- Provider detail screen
- List and map views
- Basic UI components
- Project architecture (lib/core, lib/models, lib/providers, lib/screens, lib/services, lib/widgets)

### Changed
- Initial commit with Flutter project structure

## [0.0.1] - 2026-09-08

### Added
- Project initialization
- Flutter app scaffold
- Basic dependencies setup

---

## Versioning

For the versions available, see the [tags on this repository](https://github.com/your-org/servmarket/tags).

## Categories

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes
