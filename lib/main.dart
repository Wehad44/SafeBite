import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const LoginPage(), // 🔥 نبدأ من اللوقن
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
  String _result = 'No detection yet';
  String _message = '';
  List<dynamic> _detectedAllergens = [];
  List<dynamic> _recommendations = [];
  bool _isLoading = false;

  final String apiUrl = 'http://10.0.2.2:5000/analyze';

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _result = 'Image selected';
        _message = '';
        _detectedAllergens = [];
        _recommendations = [];
      });
    }
  }

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
          _recommendations = [];
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
        _message = 'Camera error';
      });
    }
  }

  Future<void> _detectImage() async {
    if (_selectedImage == null) {
      setState(() {
        _result = 'Please select an image first';
        _message = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _detectedAllergens = [];
      _recommendations = [];
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
          _recommendations = data['recommendations'] ?? [];
        });
      } else {
        setState(() {
          _result = 'Error';
          _message = 'Server error: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error';
        _message = 'Failed to connect to API';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getColor() {
    if (_result == 'Safe') return Colors.green;
    if (_result == 'Not Safe') return Colors.red;
    if (_result == 'Unclear') return Colors.orange;
    if (_result == 'Error') return Colors.red;
    return Colors.black;
  }

  void _openRecommendationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationsPage(
          recommendations: _recommendations,
          detectedAllergens: _detectedAllergens,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('SafeBite'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(child: Text('No image selected')),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _pickImageFromGallery, child: const Text('Upload')),
            ElevatedButton(onPressed: _pickImageFromCamera, child: const Text('Camera')),
            ElevatedButton(onPressed: _detectImage, child: const Text('Detect')),
            const SizedBox(height: 12),
            Text(_result, style: TextStyle(fontSize: 22, color: _getColor())),
            if (_result == 'Not Safe' && _recommendations.isNotEmpty)
              ElevatedButton(
                onPressed: _openRecommendationsPage,
                child: const Text('View Recommendations'),
              ),
          ],
        ),
      ),
    );
  }
}

class RecommendationsPage extends StatelessWidget {
  final List<dynamic> recommendations;
  final List<dynamic> detectedAllergens;

  const RecommendationsPage({
    super.key,
    required this.recommendations,
    required this.detectedAllergens,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: recommendations.map((rec) {
          return Card(
            child: ListTile(
              title: Text(rec['product_name'] ?? ''),
              subtitle: Text(rec['main_category'] ?? ''),
            ),
          );
        }).toList(),
      ),
    );
  }
}