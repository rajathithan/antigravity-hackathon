/// API endpoint paths — all relative to the app's own origin.
/// The Flutter web app only ever talks to its own Cloud Run service.
/// The backend (api_server.py) uses the Cloud Run service account
/// via Application Default Credentials to access GCS and Firestore.
class AppConfig {
  /// GCS bucket name — displayed in the admin UI for reference.
  static const String gcsBucket = 'four-to-eight-fine-dine';

  /// GET  — returns today's dishes (public, no auth).
  static const String apiMenu = '/api/menu';

  /// POST — multipart upload of a dish image (requires X-Admin-Secret).
  static const String apiUploadImage = '/api/upload-image';

  /// POST — writes today's menu document to Firestore (requires X-Admin-Secret).
  static const String apiPublishMenu = '/api/publish-menu';
}
