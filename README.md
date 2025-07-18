# DecentraFor - Educational Platform

A comprehensive Flutter application that combines PDF document management with educational forum discussions, designed for decentralized learning and knowledge sharing.

## Overview

DecentraFor is an educational platform that combines two powerful features:
1. **PDF Document Store**: A comprehensive library for storing, managing, and accessing educational PDFs
2. **Educational Forum**: A community-driven discussion platform for knowledge sharing and learning

The application is built with Flutter and Supabase, providing a modern, responsive experience across all platforms.

## Core Features

### � PDF Document Store
- �📱 Modern Flutter UI with Material Design 3
- 🔍 Search PDFs by title and description
- 📂 Filter PDFs by category
- 📄 View PDFs directly in the app
- ⬇️ **Download PDFs for offline viewing**
- 📱 **Manage downloaded PDFs with dedicated Downloads screen**
- ⬆️ Upload new PDFs to Supabase Storage
- 🗂️ Organize PDFs with categories and tags
- 📊 Real-time updates with Supabase
- 🔄 Progress tracking for downloads
- 💾 Automatic offline detection

### 💬 Educational Forum
- 🏠 **Category-based Organization**: Topics organized into educational categories
- 📚 **Subject Categories**: Mathematics, Science, Literature, History, Technology, Art & Design, Language Learning, and General Discussion
- 💬 **Topic Management**: Create, view, and participate in educational discussions
- 📝 **Post & Reply System**: Threaded discussions with rich text content
- 👍 **Like System**: Users can like/unlike posts
- 🔍 **Search Functionality**: Search across all topics by title and description
- 📊 **Statistics Display**: Shows topic and post counts for each category
- 🔐 **User Authentication**: Secure user accounts with Supabase Auth
- 🎯 **Modern UI**: Beautiful card-based interface with gradients and icons

### 🔒 Security & Authentication
- **Row Level Security**: Comprehensive RLS policies for all database tables
- **Username Management**: Unique username system for forum participation
- **Access Control**: Proper permissions for creating, editing, and deleting content

## Future Roadmap

### 🌐 Mesh Network Integration (Coming Soon)
DecentraFor is designed with decentralization in mind. The next major feature will be:

- **Offline Mesh Networking**: Enable peer-to-peer communication without internet connectivity
- **Distributed Content Sharing**: Share PDFs and forum discussions across mesh networks
- **Offline Forum Sync**: Synchronize forum discussions when devices connect
- **Decentralized Storage**: Reduce dependency on centralized servers
- **Emergency Communication**: Maintain educational access in remote or crisis situations
- **Bandwidth Optimization**: Efficient content distribution across mesh nodes

This will make DecentraFor truly decentralized, allowing educational communities to function independently of traditional internet infrastructure.

## Setup Instructions

### 1. Supabase Setup

1. Create a new project in [Supabase](https://supabase.com)
2. Go to the SQL Editor in your Supabase dashboard
3. Run the SQL script from `supabase_setup.sql` to create the necessary tables and policies
4. Go to Storage and create a new bucket called `pdfs` with public access
5. Update the Supabase URL and API key in `lib/config/supabase_config.dart` if needed

### 2. Flutter Setup

1. Make sure you have Flutter installed and configured
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### 2. Database Setup

The application uses several database tables:

#### PDF Management Tables:
- `pdfs`: Stores PDF metadata and file information
- `pdf_categories`: Categories for organizing PDFs
- `pdf_tags`: Tags for enhanced searchability

#### Forum Tables:
- `forum_categories`: Discussion categories (Mathematics, Science, etc.)
- `forum_topics`: Discussion topics within categories
- `forum_posts`: Posts and replies within topics
- `forum_topic_views`: Tracks topic view counts
- `forum_post_likes`: Manages post like/unlike functionality

#### User Management:
- `user_profiles`: Extended user profile information
- `usernames`: Unique username system for forum participation

Run the SQL scripts in the `sql_and_mk/` directory to set up the complete database schema:
1. `supabase_setup.sql` - Basic PDF functionality
2. `forum_schema.sql` - Forum system setup
3. `admin_auth_setup.sql` - Admin authentication setup

### 3. Storage Configuration

The app uses Supabase Storage for file management:
- **PDFs Bucket**: Store PDF documents with public access
- **Thumbnails**: Optional thumbnail images for PDFs
- **User Avatars**: Profile pictures for forum users

Create the following buckets in your Supabase Storage:
1. `pdfs` - For PDF documents (public access)
2. `thumbnails` - For PDF thumbnails (public access)
3. `avatars` - For user profile pictures (public access)

## Usage

### PDF Store Features

1. **Browse PDFs**: The main PDF store screen shows all PDFs in a grid layout
2. **Search**: Use the search bar to find PDFs by title or description
3. **Filter**: Use category chips to filter PDFs by category
4. **View PDF**: Tap on any PDF card to open it in the viewer
5. **Download PDF**: Tap the download icon on any PDF card to save it for offline viewing
6. **Manage Downloads**: Use the Downloads button in the app bar to view and manage downloaded PDFs
7. **Offline Viewing**: Downloaded PDFs can be viewed without an internet connection
8. **Add PDF**: Tap the + button to upload a new PDF
9. **Categories**: PDFs can be organized into categories: Business, Education, Technology, Science, Health, Entertainment, Other

### Forum Features

1. **Browse Categories**: Navigate through educational categories on the main forum screen
2. **Create Account**: Register and set up your username for forum participation
3. **Join Discussions**: Participate in existing topics or create new ones
4. **Search Topics**: Use the search functionality to find specific discussions
5. **Post Replies**: Engage in threaded discussions with other users
6. **Like Posts**: Show appreciation for helpful posts
7. **Track Activity**: View topic statistics and your participation history

### Download Management

- **Progressive Download**: Real-time progress tracking with percentage and progress bar
- **Offline Viewing**: Downloaded PDFs are stored locally and can be viewed without internet
- **Download Management**: Dedicated Downloads screen to manage all downloaded files
- **Storage Info**: View download location and file sizes
- **Delete Downloads**: Remove downloaded files to free up space
- **Download Status**: Visual indicators show which PDFs are downloaded

## Dependencies

### Core Dependencies
- `supabase_flutter`: Supabase client for Flutter
- `provider`: State management
- `flutter`: Flutter framework

### PDF Management
- `syncfusion_flutter_pdfviewer`: PDF viewer widget
- `flutter_pdfview`: Alternative PDF viewer
- `file_picker`: File selection for uploads

### Forum & Social Features
- `cached_network_image`: Image caching for avatars
- `flutter_spinkit`: Loading animations
- `intl`: Internationalization and date formatting

### Network & Storage
- `dio`: HTTP client for downloads
- `http`: HTTP requests
- `path_provider`: File system paths
- `permission_handler`: Storage permissions

### UI Components
- `cupertino_icons`: iOS-style icons
- `flutter_native_splash`: Custom splash screens

### Future Mesh Network Dependencies (Planned)
- `nearby_connections`: Peer-to-peer communication
- `connectivity_plus`: Network state monitoring
- `network_info_plus`: Network information
- `flutter_blue_plus`: Bluetooth connectivity for mesh networks

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart     # Supabase configuration
├── models/
│   ├── pdf_document.dart        # PDF document model
│   ├── forum_category.dart      # Forum category model
│   ├── forum_topic.dart         # Forum topic model
│   ├── forum_post.dart          # Forum post model
│   └── user_profile.dart        # User profile model
├── providers/
│   ├── pdf_provider.dart        # PDF state management
│   ├── forum_provider.dart      # Forum state management
│   └── username_provider.dart   # User authentication state
├── screens/
│   ├── pdf_store_screen.dart    # Main PDF list screen
│   ├── pdf_viewer_screen.dart   # PDF viewer screen
│   ├── add_pdf_screen.dart      # Add new PDF screen
│   ├── downloads_screen.dart    # Downloaded PDFs management
│   ├── forum_screen.dart        # Main forum screen
│   ├── forum_category_screen.dart # Category-specific topics
│   ├── forum_topic_screen.dart  # Topic discussion screen
│   ├── forum_search_screen.dart # Forum search functionality
│   └── account_screen.dart      # User account management
├── services/
│   ├── pdf_service.dart         # Supabase PDF API service
│   ├── forum_service.dart       # Forum API service
│   └── download_service.dart    # Download management service
├── widgets/
│   ├── pdf_card.dart           # PDF display widgets
│   ├── forum_widgets.dart      # Forum UI components
│   └── common_widgets.dart     # Shared UI components
└── main.dart                   # App entry point
```

### SQL Scripts Directory
```
sql_and_mk/
├── supabase_setup.sql          # Basic PDF functionality setup
├── forum_schema.sql            # Forum system database schema
├── admin_auth_setup.sql        # Admin authentication setup
├── FORUM_DOCUMENTATION.md     # Detailed forum feature documentation
├── PDF_UPLOAD_PERMISSION_FIX.md # PDF upload troubleshooting
└── USERNAME_FORUM_SETUP.md    # Username system documentation
```

## Architecture & Design

### Current Architecture
- **Frontend**: Flutter with Material Design 3
- **Backend**: Supabase (PostgreSQL database + Authentication + Storage)
- **State Management**: Provider pattern
- **Real-time Updates**: Supabase real-time subscriptions
- **File Storage**: Supabase Storage buckets

### Security Features
- **Row Level Security (RLS)**: All database tables protected with comprehensive policies
- **User Authentication**: Secure login/registration with Supabase Auth
- **Access Control**: Proper permissions for all CRUD operations
- **Data Validation**: Input validation and sanitization

### Offline Capabilities
- **Downloaded PDFs**: Local storage for offline PDF viewing
- **Caching**: Efficient image and data caching
- **Progress Tracking**: Real-time download progress indicators

## Technical Specifications

### Supported Platforms
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

### System Requirements
- Flutter 3.8.1 or higher
- Dart 3.0 or higher
- Supabase account and project
- Internet connection for initial setup and synchronization

## Security Note

The current configuration implements:
- **Row Level Security**: Database-level access control
- **Input Validation**: Proper sanitization of user inputs
- **Secure File Upload**: Validated file types and sizes

For production deployment, consider:
1. Implementing additional rate limiting
2. Adding content moderation for forum posts
3. Setting up proper backup and recovery procedures
4. Implementing audit logging for admin actions

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Maintain code documentation
- Add tests for new features
- Update README for significant changes

## Roadmap

### Phase 1: Current Features ✅
- PDF document management
- Educational forum system
- User authentication
- Offline PDF viewing

### Phase 2: Enhanced Features 🔄
- Advanced search and filtering
- User profiles and avatars
- Notification system
- Content moderation tools

### Phase 3: Mesh Network Integration 🔮
- Peer-to-peer connectivity
- Offline synchronization
- Distributed content sharing
- Emergency communication modes

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation in the `sql_and_mk/` directory
- Review the inline code comments

---

**DecentraFor** - Empowering decentralized education and knowledge sharing.
