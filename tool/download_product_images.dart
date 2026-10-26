import 'dart:convert';
import 'dart:io';

void main() async {
  print('Starting product images download from Firebase...');
  
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);

  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/stleaf-trading/databases/(default)/documents/products?pageSize=300',
  );

  final req = await client.getUrl(url);
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final data = jsonDecode(body) as Map<String, dynamic>;
  final docs = (data['documents'] as List<dynamic>?) ?? [];

  print('Found ${docs.length} products in Firestore.');

  final targetDir = Directory('assets/images/products');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
    print('Created directory: ${targetDir.path}');
  }

  int successCount = 0;
  int failCount = 0;
  int skipCount = 0;
  int totalBytes = 0;

  final Map<String, String> codeToAsset = {};

  for (int i = 0; i < docs.length; i++) {
    final doc = docs[i];
    final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
    final code = (fields['itemCode']?['stringValue'] ?? '').trim();
    final name = (fields['name']?['stringValue'] ?? 'Unknown').trim();
    final imgUrl = fields['imageUrl']?['stringValue'];

    if (code.isEmpty || imgUrl == null || imgUrl.isEmpty) {
      skipCount++;
      continue;
    }

    // Clean code for file name (e.g. VG-001 -> VG-001.jpg)
    final safeCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath = 'assets/images/products/$safeCode.jpg';
    final file = File(filePath);

    try {
      final imgUri = Uri.parse(imgUrl);
      final imgReq = await client.getUrl(imgUri);
      final imgResp = await imgReq.close();

      if (imgResp.statusCode == 200) {
        final bytes = await imgResp.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );
        await file.writeAsBytes(bytes);
        totalBytes += bytes.length;
        successCount++;
        codeToAsset[code.toLowerCase()] = filePath;
        print('[$successCount/${docs.length}] Saved $safeCode ($name): ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      } else {
        failCount++;
        print('[FAIL] $safeCode ($name) HTTP ${imgResp.statusCode}');
      }
    } catch (e) {
      failCount++;
      print('[ERROR] $safeCode ($name): $e');
    }

    // Gentle throttling: 50ms pause between downloads
    await Future.delayed(const Duration(milliseconds: 50));
  }

  // Save index mapping file
  final indexFile = File('assets/images/products/product_asset_manifest.json');
  await indexFile.writeAsString(const JsonEncoder.withIndent('  ').convert(codeToAsset));

  client.close();

  print('\n=== Download Summary ===');
  print('Total products: ${docs.length}');
  print('Successfully saved: $successCount');
  print('Failed: $failCount');
  print('Skipped: $skipCount');
  print('Total data downloaded: ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('Index file generated at: ${indexFile.path}');
}
