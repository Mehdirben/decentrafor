# PDF Store Flutter App

A Flutter application for managing and viewing PDF documents stored in Supabase.

## Features

- 📱 Modern Flutter UI with Material Design 3
- 🔍 Search PDFs by title and description
- 📂 Filter PDFs by category
- 📄 View PDFs directly in the app
- ⬆️ Upload new PDFs to Supabase Storage
- 🗂️ Organize PDFs with categories and tags
- 📊 Real-time updates with Supabase

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

### 3. Database Structure

The app uses a `pdfs` table with the following structure:
- `id`: UUID primary key
- `title`: PDF title
- `description`: PDF description
- `file_name`: Original filename
- `file_url`: Public URL to the PDF file
- `file_size`: File size in bytes
- `category`: PDF category
- `tags`: Array of tags
- `thumbnail_url`: Optional thumbnail URL
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### 4. Storage Bucket

PDFs are stored in a Supabase Storage bucket named `pdfs`. The bucket should be configured with public access to allow viewing of PDFs.

## Usage

1. **Browse PDFs**: The main screen shows all PDFs in a grid layout
2. **Search**: Use the search bar to find PDFs by title or description
3. **Filter**: Use category chips to filter PDFs by category
4. **View PDF**: Tap on any PDF card to open it in the viewer
5. **Add PDF**: Tap the + button to upload a new PDF
6. **Categories**: PDFs can be organized into categories: Business, Education, Technology, Science, Health, Entertainment, Other

## Dependencies

- `supabase_flutter`: Supabase client for Flutter
- `syncfusion_flutter_pdfviewer`: PDF viewer widget
- `provider`: State management
- `file_picker`: File selection
- `cached_network_image`: Image caching
- `flutter_spinkit`: Loading animations

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart     # Supabase configuration
├── models/
│   └── pdf_document.dart        # PDF document model
├── providers/
│   └── pdf_provider.dart        # State management
├── screens/
│   ├── pdf_store_screen.dart    # Main PDF list screen
│   ├── pdf_viewer_screen.dart   # PDF viewer screen
│   └── add_pdf_screen.dart      # Add new PDF screen
├── services/
│   └── pdf_service.dart         # Supabase API service
└── main.dart                    # App entry point
```

## Security Note

The current configuration allows public access to all PDFs. For production use, you should implement proper authentication and authorization by:
1. Setting up Supabase Auth
2. Updating the RLS policies to restrict access based on user roles
3. Implementing user authentication in the Flutter app

## Contributing

Feel free to submit issues and pull requests to improve the app!

## License

This project is open source and available under the [MIT License](LICENSE).
