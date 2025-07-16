# Project Structure

## Root Directory Layout
```
decentrafor_appli/
├── lib/                     # Main Dart source code
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── web/                     # Web-specific files
├── windows/                 # Windows-specific files
├── macos/                   # macOS-specific files
├── linux/                   # Linux-specific files
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Dependencies and project config
├── analysis_options.yaml    # Dart linting configuration
└── README.md               # Project documentation
```

## Core Application Structure (`lib/`)
```
lib/
├── main.dart               # App entry point and initialization
├── config/
│   └── supabase_config.dart    # Supabase configuration constants
├── models/
│   └── pdf_document.dart       # PDF document data model
├── providers/
│   └── pdf_provider.dart       # State management (Provider pattern)
├── screens/
│   ├── pdf_store_screen.dart   # Main PDF browsing screen
│   ├── pdf_viewer_screen.dart  # PDF viewing screen
│   ├── add_pdf_screen.dart     # PDF upload screen
│   ├── downloads_screen.dart   # Downloaded PDFs management
│   └── storage_screen.dart     # Storage management screen
└── services/
    ├── pdf_service.dart        # Supabase API interactions
    ├── download_service.dart   # Download management
    └── storage_service.dart    # Local storage operations
```

## Database Setup Files
- `supabase_setup.sql` - Initial database schema and RLS policies
- `add_test_data.sql` - Sample data for development
- `setup_with_test_data.sql` - Combined setup with test data
- `fix_rls_policies.sql` - RLS policy fixes
- `SUPABASE_FIX_INSTRUCTIONS.sql` - Troubleshooting guide

## Naming Conventions

### Files & Directories
- Use `snake_case` for file and directory names
- Screen files: `*_screen.dart`
- Service files: `*_service.dart`
- Model files: `*_model.dart` or descriptive names like `pdf_document.dart`
- Provider files: `*_provider.dart`

### Dart Code
- Classes: `PascalCase` (e.g., `PdfDocument`, `PdfService`)
- Variables/functions: `camelCase` (e.g., `fileName`, `getAllPdfs()`)
- Constants: `camelCase` (e.g., `supabaseUrl`)
- Private members: prefix with `_` (e.g., `_client`)

## Architecture Guidelines

### Screen Organization
- Each screen is a separate file in `screens/`
- Screens use Provider for state management
- UI logic separated from business logic

### Service Layer
- All external API calls go through service classes
- Services are static utility classes
- Error handling at service level with meaningful exceptions

### State Management
- Use Provider pattern for app-wide state
- Providers in `providers/` directory
- ChangeNotifier for reactive state updates

### Models
- Plain Dart classes with `fromJson`/`toJson` methods
- Include helper methods for data formatting
- Immutable where possible

## Platform-Specific Considerations
- Platform folders contain native configuration
- No platform-specific Dart code in `lib/`
- Use Flutter's platform detection for conditional logic
- Permissions handled through `permission_handler` package