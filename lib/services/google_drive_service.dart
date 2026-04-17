import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
// ignore: unused_import
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'storage_service.dart';

class GoogleDriveService {
  // Web OAuth Client ID from Google Cloud Console
  // This is required for Google Sign-In on Android
  static const String _serverClientId = '860525595777-5crld215v8q079tnan6q9vdrmun3ng7u.apps.googleusercontent.com';

  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;

  static final List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  // Get or create GoogleSignIn instance
  static GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn.instance;
      // Initialize with server client ID
      _googleSignIn!.initialize(serverClientId: _serverClientId);
    }
    return _googleSignIn!;
  }

  // Sign in to Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // If already signed in, return current user
      if (_currentUser != null) {
        return _currentUser;
      }

      final googleSignIn = _getGoogleSignIn();

      // Check if authenticate is supported
      if (!googleSignIn.supportsAuthenticate()) {
        throw Exception('Google Sign-In not supported on this platform');
      }

      // Authenticate the user with scope hints
      // Note: On Android, this may fail if serverClientId is not configured
      // but we'll try anyway
      try {
        _currentUser = await googleSignIn.authenticate(
          scopeHint: _scopes,
        );
      } catch (e) {
        print('Authenticate with scopeHint failed: $e');
        // Try without scopeHint
        _currentUser = await googleSignIn.authenticate();
      }

      if (_currentUser == null) {
        throw Exception('Sign in was cancelled');
      }

      return _currentUser;
    } catch (e) {
      // Log error for debugging
      print('Sign in error: $e');
      _currentUser = null;
      rethrow;
    }
  }

  // Sign out from Google
  static Future<void> signOut() async {
    final googleSignIn = _getGoogleSignIn();
    await googleSignIn.signOut();
    _currentUser = null;
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    return _currentUser != null;
  }

  // Get current user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _currentUser;
  }

  // Backup database to Google Drive
  static Future<String> backupToGoogleDrive() async {
    try {
      // Ensure user is signed in
      final account = _currentUser ?? await signIn();
      if (account == null) {
        throw Exception('User not signed in');
      }

      // Get authenticated HTTP client using the extension
      // The extension provides authenticatedClient() method on GoogleSignIn
      final googleSignIn = _getGoogleSignIn();
      final authClient = await (googleSignIn as dynamic).authenticatedClient();
      if (authClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final driveApi = drive.DriveApi(authClient);

      // Get database path
      final db = await StorageService.database;
      final dbPath = db.path;

      // Read database file
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      final dbBytes = await dbFile.readAsBytes();

      // Create backup metadata
      final timestamp = DateTime.now().toIso8601String();
      final fileName = 'expense_manager_backup_$timestamp.db';

      // Check if backup folder exists
      String? folderId = await _getOrCreateBackupFolder(driveApi);

      // Create file metadata
      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [folderId];
      driveFile.description = 'Expense Manager Database Backup';

      // Upload file
      final media = drive.Media(Stream.value(dbBytes), dbBytes.length);
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return 'Backup successful: ${uploadedFile.name}';
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  // Restore database from Google Drive
  static Future<String> restoreFromGoogleDrive() async {
    try {
      // Ensure user is signed in
      final account = _currentUser ?? await signIn();
      if (account == null) {
        throw Exception('User not signed in');
      }

      // Get authenticated HTTP client
      final googleSignIn = _getGoogleSignIn();
      final authClient = await (googleSignIn as dynamic).authenticatedClient();
      if (authClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final driveApi = drive.DriveApi(authClient);

      // Find backup folder
      String? folderId = await _findBackupFolder(driveApi);
      if (folderId == null) {
        throw Exception('No backup folder found');
      }

      // List backup files
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and name contains 'expense_manager_backup' and trashed=false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backup files found');
      }

      // Get the most recent backup
      final latestBackup = fileList.files!.first;

      // Download the backup file
      final media = await driveApi.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the downloaded data
      final List<int> dataStore = [];
      await for (var data in media.stream) {
        dataStore.addAll(data);
      }

      // Close existing database connection
      final db = await StorageService.database;
      final dbPath = db.path;
      await db.close();
      StorageService.closeDatabase();

      // Write the backup to database file
      final dbFile = File(dbPath);
      await dbFile.writeAsBytes(dataStore);

      // Reinitialize database
      await StorageService.init();

      return 'Restore successful from: ${latestBackup.name}';
    } catch (e) {
      // Reinitialize database even if restore fails
      await StorageService.init();
      throw Exception('Restore failed: $e');
    }
  }

  // Get or create backup folder
  static Future<String> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    // Try to find existing folder
    final folderId = await _findBackupFolder(driveApi);
    if (folderId != null) {
      return folderId;
    }

    // Create new folder
    final folder = drive.File();
    folder.name = 'ExpenseManagerBackups';
    folder.mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  // Find backup folder
  static Future<String?> _findBackupFolder(drive.DriveApi driveApi) async {
    final folderList = await driveApi.files.list(
      q: "name='ExpenseManagerBackups' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      $fields: 'files(id, name)',
    );

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id;
    }

    return null;
  }

  // List all backups
  static Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      // Ensure user is signed in
      final account = _currentUser ?? await signIn();
      if (account == null) {
        throw Exception('User not signed in');
      }

      // Get authenticated HTTP client
      final googleSignIn = _getGoogleSignIn();
      final authClient = await (googleSignIn as dynamic).authenticatedClient();
      if (authClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final driveApi = drive.DriveApi(authClient);

      // Find backup folder
      String? folderId = await _findBackupFolder(driveApi);
      if (folderId == null) {
        return [];
      }

      // List backup files
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and name contains 'expense_manager_backup' and trashed=false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return [];
      }

      return fileList.files!.map((file) {
        return {
          'id': file.id,
          'name': file.name,
          'createdTime': file.createdTime?.toIso8601String(),
          'size': file.size,
        };
      }).toList();
    } catch (e) {
      // Error listing backups
      return [];
    }
  }

  // Delete a specific backup
  static Future<void> deleteBackup(String fileId) async {
    try {
      final googleSignIn = _getGoogleSignIn();
      final authClient = await (googleSignIn as dynamic).authenticatedClient();
      if (authClient == null) {
        throw Exception('Failed to get authenticated client');
      }

      final driveApi = drive.DriveApi(authClient);
      await driveApi.files.delete(fileId);
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }
}

