import 'package:supabase_flutter/supabase_flutter.dart';

import 'week3_supabase_config.dart';
import 'week4_messaging_service.dart';

class SupabaseMessagingService {
  static RealtimeChannel? _channel;

  static Future<void> init() async {
    await ensureWeek3SupabaseInitialized();
    final supabase = week3SupabaseClient;

    _channel = supabase.channel('paml_notifications');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'campaigns',
          callback: (payload) {
            try {
              final p = payload as dynamic;
              Map<String, dynamic>? newRow;

              if (p is Map<String, dynamic>) {
                newRow = (p['new'] as Map<String, dynamic>?) ??
                    (p['record'] as Map<String, dynamic>?) ??
                    p;
              } else {
                // try multiple strategies to extract the inserted row
                try {
                  final cand = p['new'];
                  if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                } catch (_) {}
                if (newRow == null) {
                  try {
                    final cand = p['record'];
                    if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                  } catch (_) {}
                }
                if (newRow == null) {
                  try {
                    final cand = p.newRecord ?? p.record ?? p.payload;
                    if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                  } catch (_) {}
                }
              }

              final title = (newRow != null && newRow['title'] != null)
                  ? newRow['title'].toString()
                  : 'Campaign baru';
              final body = (newRow != null && newRow['description'] != null)
                  ? newRow['description'].toString()
                  : 'Ada campaign baru tersedia';

              MessagingService.showLocalNotification(
                  title: 'Campaign: $title', body: body);
            } catch (_) {
              MessagingService.showLocalNotification(
                  title: 'Campaign baru', body: 'Ada campaign baru tersedia');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'donations',
          callback: (payload) {
            try {
              final p = payload as dynamic;
              Map<String, dynamic>? newRow;

              if (p is Map<String, dynamic>) {
                newRow = (p['new'] as Map<String, dynamic>?) ??
                    (p['record'] as Map<String, dynamic>?) ??
                    p;
              } else {
                try {
                  final cand = p['new'];
                  if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                } catch (_) {}
                if (newRow == null) {
                  try {
                    final cand = p['record'];
                    if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                  } catch (_) {}
                }
                if (newRow == null) {
                  try {
                    final cand = p.newRecord ?? p.record ?? p.payload;
                    if (cand is Map<String, dynamic>) newRow = Map.from(cand);
                  } catch (_) {}
                }
              }

              String body;
              if (newRow is Map<String, dynamic>) {
                final amount = newRow['amount']?.toString() ?? 'sebuah donasi';
                final campaignTitle = newRow['campaignTitle'] ??
                    newRow['campaign_id'] ??
                    newRow['campaignId'] ??
                    '';
                body = 'Donasi $amount untuk ${campaignTitle.toString()}';
              } else {
                body = 'Donasi baru diterima';
              }

              MessagingService.showLocalNotification(
                  title: 'Donasi diterima', body: body);
            } catch (_) {
              MessagingService.showLocalNotification(
                  title: 'Donasi diterima', body: 'Donasi baru diterima');
            }
          },
        )
        .subscribe();
  }

  static Future<void> dispose() async {
    if (_channel != null) {
      await week3SupabaseClient.removeChannel(_channel!);
      _channel = null;
    }
  }
}
