import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SafeBiteApp());
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _result = 'No analysis yet';
  String _message = '';
  List<dynamic> _detectedAllergens = [];
  bool _isLoading = false;

  final String apiUrl = 'http://10.0.2.2:5000/analyze';

  // 📷 اختيار من المعرض
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _result = 'Image selected';
        _message = '';
        _detectedAllergens = [];
      });
    }
  }

  // 📸 الكاميرا (معدلة بدون مشاكل)
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = 'Image captured';
          _message = '';
          _detectedAllergens = [];
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
        _message = 'Camera error';
      });
    }
  }

  // 🔍 تحليل الصورة
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      setState(() {
        _result = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );

      var response = await request.send();
      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _result = data['result'] ?? 'Unknown';
          _message = data['message'] ?? '';
          _detectedAllergens = data['detected_allergens'] ?? [];
        });
      } else {
        setState(() {
          _result = 'Error';
          _message = 'Server error';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
        _message = 'Failed to connect to API';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Color _getColor() {
    if (_result == 'Safe') return Colors.green;
    if (_result == 'Not Safe') return Colors.red;
    if (_result == 'Unclear') return Colors.orange;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('SafeBite'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📷 صورة
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Center(child: Text("No image selected")),
              ),
            ),

            const SizedBox(height: 16),

            // أزرار
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Analyze
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeImage,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Detect Allergen"),
            ),

            const SizedBox(height: 16),

            // النتيجة
            Text(
              _result,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),

            Text(_message),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: _detectedAllergens
                  .map((e) => Chip(label: Text(e.toString())))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
