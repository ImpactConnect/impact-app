# Google Drive URL Support in PDF Reader

The PDF reader now supports loading books from Google Drive URLs in addition to regular PDF URLs.

## Supported Google Drive URL Formats

1. **File sharing URLs**: `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
2. **Direct file URLs**: `https://drive.google.com/file/d/FILE_ID/view`
3. **Open URLs**: `https://drive.google.com/open?id=FILE_ID`
4. **Document URLs**: `https://docs.google.com/document/d/FILE_ID/edit`

## How It Works

### URL Processing
- The `UrlUtils` class automatically detects Google Drive URLs
- Extracts the file ID from various URL formats
- Converts them to appropriate viewing URLs

### Viewing Modes

1. **Google Drive Preview** (Default for Google Drive URLs)
   - Uses `https://drive.google.com/file/d/FILE_ID/preview`
   - Best for publicly accessible files

2. **Direct Download**
   - Uses `https://drive.google.com/uc?export=download&id=FILE_ID`
   - Good for files that allow direct download

3. **External App**
   - Opens the processed URL in the device's default PDF viewer

4. **Try Original URL**
   - Falls back to the original Google Drive URL
   - Useful when other methods fail

### Error Handling

- If a Google Drive file fails to load, the app provides specific guidance
- Multiple fallback options are available through the menu
- Clear error messages explain potential permission issues

## Requirements for Google Drive Files

1. **Public Access**: Files should be set to "Anyone with the link can view"
2. **File Type**: Must be a PDF file
3. **Size Limits**: Large files may take longer to load

## Usage in Book Model

Simply add the Google Drive URL to the `pdfUrl` field in the Book model:

```dart
Book(
  id: 'book_id',
  title: 'My Book',
  author: 'Author Name',
  pdfUrl: 'https://drive.google.com/file/d/1kQq-EYEbHgzDvVXkzajcIzIJKe6z4O1D/view?usp=drive_link',
  // ... other fields
)
```

The PDF reader will automatically detect and handle the Google Drive URL appropriately.

## Troubleshooting

- **File won't load**: Check if the file is publicly accessible
- **Permission denied**: Ensure the file sharing settings allow public access
- **Slow loading**: Large files may take time to load, try external app option
- **Format issues**: Ensure the file is actually a PDF