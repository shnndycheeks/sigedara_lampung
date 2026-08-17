import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final client = Supabase.instance.client;
  print('Fetching peminjaman...');
  try {
    final res = await client
        .from('peminjaman')
        .select('*')
        .limit(2);

    if (res.isEmpty) {
      print('No peminjaman found');
      return;
    }

    print('PEMINJAMAN ROW count: ${res.length}');
    for (var r in res) {
      print('KEYS: ${r.keys.toList()}');
      print('ROW: $r');
    }
  } catch (e) {
    print('Error: $e');
  }
}
