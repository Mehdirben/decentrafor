# Technology Stack

## Framework & Language
- **Flutter 3.8.1+** - Cross-platform mobile framework
- **Dart** - Primary programming language
- **Material Design 3** - UI design system

## Backend & Database
- **Supabase** - Backend-as-a-Service (PostgreSQL database + Storage + Auth)
- **Supabase Storage** - File storage for PDF documents
- **Real-time subscriptions** - Live data updates

## Key Dependencies
- `supabase_flutter: ^2.5.6` - Supabase client
- `syncfusion_flutter_pdfviewer: ^30.1.40` - PDF viewing
- `provider: ^6.1.2` - State management
- `dio: ^5.7.0` - HTTP client for downloads
- `file_picker: ^8.1.2` - File selection
- `path_provider: ^2.1.4` - File system access
- `permission_handler: ^11.3.1` - Device permissions
- `cached_network_image: ^3.4.1` - Image caching

## Development Tools
- `flutter_lints: ^5.0.0` - Dart/Flutter linting rules
- Standard Flutter testing framework

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific platform
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios          # iOS

# Hot reload during development
r                            # Hot reload
R                            # Hot restart
```

### Build & Release
```bash
# Build for production
flutter build apk           # Android APK
flutter build appbundle     # Android App Bundle
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
flutter build macos        # macOS
flutter build linux        # Linux

# Analyze code
flutter analyze

# Run tests
flutter test
```

### Maintenance
```bash
# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Clean build cache
flutter clean
```

## Architecture Patterns
- **Provider Pattern** - State management
- **Service Layer** - Business logic separation
- **Repository Pattern** - Data access abstraction
- **Model-View-Provider (MVP)** - UI architecture