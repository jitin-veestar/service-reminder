import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:service_reminder/core/constants/app_constants.dart';

Future<String> uploadServiceRecording({
  required SupabaseClient client,
  required String customerId,
  required String localFilePath,
}) async {
  final uid = client.auth.currentUser!.id;
  final objectName = '${const Uuid().v4()}.m4a';
  final path = '$uid/$customerId/$objectName';
  final bytes = await File(localFilePath).readAsBytes();
  await client.storage.from(AppConstants.serviceRecordingsBucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'audio/m4a'),
      );
  return path;
}
