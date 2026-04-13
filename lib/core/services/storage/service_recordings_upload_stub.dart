import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> uploadServiceRecording({
  required SupabaseClient client,
  required String customerId,
  required String localFilePath,
}) async {
  throw UnsupportedError('Voice note upload is not supported on this platform.');
}
