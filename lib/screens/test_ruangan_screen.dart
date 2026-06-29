import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TestRuanganScreen extends StatefulWidget {
  const TestRuanganScreen({super.key});

  @override
  State<TestRuanganScreen> createState() => _TestRuanganScreenState();
}

class _TestRuanganScreenState extends State<TestRuanganScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();

    _future = DatabaseService.getRuangan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Ruangan Supabase")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('ERROR: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('DATA KOSONG'));
          }

          final data = snapshot.data!;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ruangan = data[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruangan['nama'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Image.network(
                        ruangan['gambar_1'] ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                      const SizedBox(height: 10),

                      Text(ruangan['deskripsi'] ?? ''),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
