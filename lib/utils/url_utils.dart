/// Utility class for handling different types of URLs, especially Google Drive URLs
class UrlUtils {
  /// Checks if the URL is a Google Drive URL
  static bool isGoogleDriveUrl(String url) {
    return url.contains('drive.google.com/file/d/') || 
           url.contains('docs.google.com/document/d/') ||
           url.contains('drive.google.com/open?id=');
  }

  /// Extracts file ID from various Google Drive URL formats
  static String? extractGoogleDriveFileId(String url) {
    // Pattern for /file/d/FILE_ID format
    RegExp regex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    Match? match = regex.firstMatch(url);
    
    if (match != null) {
      return match.group(1);
    }
    
    // Pattern for /document/d/FILE_ID format
    regex = RegExp(r'/document/d/([a-zA-Z0-9_-]+)');
    match = regex.firstMatch(url);
    
    if (match != null) {
      return match.group(1);
    }
    
    // Pattern for ?id=FILE_ID format
    regex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    match = regex.firstMatch(url);
    
    if (match != null) {
      return match.group(1);
    }
    
    return null;
  }

  /// Converts Google Drive sharing URLs to direct download URLs
  /// Also handles regular PDF URLs without modification
  static String processUrlForViewing(String originalUrl) {
    // Check if it's a Google Drive URL
    if (isGoogleDriveUrl(originalUrl)) {
      // Extract file ID from Google Drive URL
      final fileId = extractGoogleDriveFileId(originalUrl);
      
      if (fileId != null) {
        // Convert to direct download URL
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    
    // Return original URL if it's not a Google Drive URL or couldn't be processed
    return originalUrl;
  }

  /// Gets the best preview URL for Google Drive files
  static String getGoogleDrivePreviewUrl(String originalUrl) {
    final fileId = extractGoogleDriveFileId(originalUrl);
    if (fileId != null) {
      return 'https://drive.google.com/file/d/$fileId/preview';
    }
    return originalUrl;
  }

  /// Gets the direct download URL for Google Drive files
  static String getGoogleDriveDownloadUrl(String originalUrl) {
    final fileId = extractGoogleDriveFileId(originalUrl);
    if (fileId != null) {
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return originalUrl;
  }

  /// Validates if a URL is properly formatted
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}