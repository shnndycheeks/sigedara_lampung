import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/supabase_config.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final client = Supabase.instance.client;
  print('Fetching arsip_surat with nomor_surat = 12354...');
  try {
    final res = await client
        .from('arsip_surat')
        .select('*, disposisi(*)')
        .eq('nomor_surat', '12354')
        .maybeSingle();

    if (res == null) {
      print('No surat found with nomor_surat = 12354');
      return;
    }

    print('SURAT DETAIL:');
    print('ID: ${res['id']}');
    print('status_global: ${res['status_global']}');
    print('deskripsi: ${res['deskripsi']}');
    
    print('\nDISPOSISI JOIN RESULT:');
    final disposisi = res['disposisi'];
    if (disposisi is List) {
      for (var d in disposisi) {
        print('- ID: ${d['id']}');
        print('  parent_disposisi_id: ${d['parent_disposisi_id']}');
        print('  dari_jabatan: ${d['dari_jabatan']}');
        print('  dari_role: ${d['dari_role']}');
        print('  kepada_jabatan: ${d['kepada_jabatan']}');
        print('  status_disposisi: ${d['status_disposisi']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
