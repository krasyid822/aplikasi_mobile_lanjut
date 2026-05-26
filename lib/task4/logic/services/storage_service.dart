import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../task3/logic/services/supabase_config.dart';

class StorageService {
  StorageFileApi get _bucket =>
      week3SupabaseClient.storage.from(week3SupabaseBucket);

  Future<String> uploadImage(File file) async {
    final extension = file.path.contains('.')
        ? file.path.split('.').last
        : 'jpg';
    final targetPath =
        'campaign/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _bucket.upload(
      targetPath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    final url = _bucket.getPublicUrl(targetPath);
    return url;
  }
}
