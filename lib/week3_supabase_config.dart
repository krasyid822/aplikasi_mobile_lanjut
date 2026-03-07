import 'package:supabase_flutter/supabase_flutter.dart';

const week3SupabaseUrl = 'https://pihgdqfrhocxeugcwptq.supabase.co';
const week3SupabaseAnonKey = 'sb_publishable_J3aZGXCiM1IzJbVBSL5_cQ_2SvdDdl9';
const week3SupabaseBucket = 'PAML';

var _week3SupabaseInitialized = false;

Future<void> ensureWeek3SupabaseInitialized() async {
  if (_week3SupabaseInitialized) return;

  await Supabase.initialize(
    url: week3SupabaseUrl,
    anonKey: week3SupabaseAnonKey,
  );

  _week3SupabaseInitialized = true;
}

SupabaseClient get week3SupabaseClient => Supabase.instance.client;
