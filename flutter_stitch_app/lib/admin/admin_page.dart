import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../data/firestore_service.dart';

// ─── Entry point: Admin login ──────────────────────────────────────────────────
//
// The admin secret is the ADMIN_SECRET env var set on the Cloud Run service.
// It is sent as the X-Admin-Secret header on every write request.
// The connection is always HTTPS on Cloud Run, so the secret is safe in transit.

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _secretCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  void _confirm() {
    if (_secretCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the admin secret.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardPage(adminSecret: _secretCtrl.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '4 TO 8',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white54, fontSize: 13, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _secretCtrl,
                  obscureText: _obscure,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onSubmitted: (_) => _confirm(),
                  decoration: InputDecoration(
                    labelText: 'Admin Secret',
                    labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Enter',
                      style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  final String adminSecret;
  const AdminDashboardPage({super.key, required this.adminSecret});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<_DishData> _dishes = List.generate(4, (i) => _DishData(index: i));
  bool _publishing = false;
  String? _statusMessage;
  bool _statusIsError = false;

  String get _todayLabel =>
      DateFormat('EEEE, MMMM d yyyy').format(DateTime.now());

  String get _todayKey => FirestoreService.dateKey(DateTime.now());

  Future<void> _pickImage(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _dishes[index].imageBytes = file.bytes;
      _dishes[index].imageName = file.name;
    });
  }

  /// Uploads an image via the backend API.
  /// Returns the public GCS URL.
  Future<String> _uploadImage(int index) async {
    final d = _dishes[index];
    if (d.imageBytes == null) return '';

    final ext = (d.imageName ?? 'photo.jpg').contains('.')
        ? d.imageName!.split('.').last
        : 'jpg';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.apiUploadImage),
    );
    request.headers['x-admin-secret'] = widget.adminSecret;
    request.fields['dish_folder'] = 'dish-${index + 1}';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      d.imageBytes!,
      filename: 'photo.$ext',
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 401) {
      throw Exception('Invalid admin secret — check the ADMIN_SECRET env var.');
    }
    if (streamed.statusCode != 200) {
      throw Exception('Image upload failed (${streamed.statusCode}): $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['url'] as String? ?? '';
  }

  Future<void> _publish() async {
    for (int i = 0; i < _dishes.length; i++) {
      final d = _dishes[i];
      if (d.nameCtrl.text.trim().isEmpty ||
          d.descCtrl.text.trim().isEmpty ||
          d.priceCtrl.text.trim().isEmpty) {
        _setStatus('Please fill in all fields for Dish ${i + 1}.', error: true);
        return;
      }
    }

    setState(() {
      _publishing = true;
      _statusMessage = null;
    });

    try {
      // Upload all images first
      final imageUrls = <String>[];
      for (int i = 0; i < _dishes.length; i++) {
        final url = await _uploadImage(i);
        imageUrls.add(url);
      }

      // Write menu to Firestore via the backend
      final response = await http.post(
        Uri.parse(AppConfig.apiPublishMenu),
        headers: {
          'Content-Type': 'application/json',
          'x-admin-secret': widget.adminSecret,
        },
        body: jsonEncode({
          'dishes': List.generate(_dishes.length, (i) => {
            'name': _dishes[i].nameCtrl.text.trim(),
            'description': _dishes[i].descCtrl.text.trim(),
            'price': _dishes[i].priceCtrl.text.trim(),
            'imageUrl': imageUrls[i],
          }),
        }),
      );

      if (response.statusCode == 401) {
        throw Exception('Invalid admin secret — check the ADMIN_SECRET env var.');
      }
      if (response.statusCode != 200) {
        throw Exception('Publish failed (${response.statusCode}): ${response.body}');
      }

      _setStatus('Menu published for $_todayKey!');
    } catch (e) {
      _setStatus('$e', error: true);
    } finally {
      setState(() => _publishing = false);
    }
  }

  void _setStatus(String msg, {bool error = false}) {
    setState(() {
      _statusMessage = msg;
      _statusIsError = error;
    });
  }

  void _signOut() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  @override
  void dispose() {
    for (final d in _dishes) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4 to 8 — Daily Menu Editor',
              style: TextStyle(
                  color: Color(0xFFD4AF37), fontSize: 16, letterSpacing: 2),
            ),
            Text(
              _todayLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white38)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Path info banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Text(
                'GCS: gs://${AppConfig.gcsBucket}/$_todayKey/dish-N/   '
                '│   Firestore: menu/$_todayKey',
                style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontFamily: 'monospace'),
              ),
            ),

            // 2-column dish grid on wide screens
            LayoutBuilder(builder: (context, constraints) {
              final twoCol = constraints.maxWidth > 900;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: List.generate(_dishes.length, (i) {
                  return SizedBox(
                    width: twoCol
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: _DishEditorCard(
                      data: _dishes[i],
                      dishNumber: i + 1,
                      onPickImage: () async {
                        await _pickImage(i);
                        setState(() {});
                      },
                      onClearImage: () => setState(() {
                        _dishes[i].imageBytes = null;
                        _dishes[i].imageName = null;
                      }),
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 32),

            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _statusIsError
                      ? '⚠ $_statusMessage'
                      : '✓ $_statusMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusIsError
                        ? Colors.redAccent
                        : const Color(0xFFD4AF37),
                    fontSize: 14,
                  ),
                ),
              ),

            ElevatedButton(
              onPressed: _publishing ? null : _publish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: _publishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      "PUBLISH TODAY'S MENU",
                      style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dish editor card ──────────────────────────────────────────────────────────

class _DishEditorCard extends StatelessWidget {
  final _DishData data;
  final int dishNumber;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const _DishEditorCard({
    required this.data,
    required this.dishNumber,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DISH $dishNumber  —  dish-$dishNumber/',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _ImagePickerArea(
            data: data,
            onPick: onPickImage,
            onClear: onClearImage,
          ),
          const SizedBox(height: 16),
          _AdminTextField(controller: data.nameCtrl, label: 'Dish Name'),
          const SizedBox(height: 12),
          _AdminTextField(
              controller: data.descCtrl,
              label: 'Description',
              maxLines: 3),
          const SizedBox(height: 12),
          _AdminTextField(
              controller: data.priceCtrl,
              label: r'Price (e.g. $38.00)'),
        ],
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final _DishData data;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _ImagePickerArea(
      {required this.data, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (data.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.memory(
              data.imageBytes!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF333333)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.white24, size: 36),
            SizedBox(height: 8),
            Text('Click to upload image',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared text field ─────────────────────────────────────────────────────────

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _AdminTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }
}

// ─── Dish data model ───────────────────────────────────────────────────────────

class _DishData {
  final int index;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  Uint8List? imageBytes;
  String? imageName;

  _DishData({required this.index});

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ─── String extension ──────────────────────────────────────────────────────────

extension on String {
  List<String> rsplit(String separator) {
    final idx = lastIndexOf(separator);
    if (idx == -1) return [this];
    return [substring(0, idx), substring(idx + 1)];
  }
}
