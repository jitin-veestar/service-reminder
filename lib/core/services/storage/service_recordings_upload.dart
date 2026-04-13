import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/services/storage/service_recordings_upload_io.dart'
    if (dart.library.html) 'package:service_reminder/core/services/storage/service_recordings_upload_stub.dart'
    as impl;

/// Uploads a local recording file; returns the Storage object path for `service_history.audio_storage_path`.
Future<String> uploadServiceRecording({
  required SupabaseClient client,
  required String customerId,
  required String localFilePath,
}) =>
    impl.uploadServiceRecording(
      client: client,
      customerId: customerId,
      localFilePath: localFilePath,
    );
