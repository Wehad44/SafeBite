import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SafeBiteApp());
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No image selected',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      elevation: 0,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _detectImage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Detect',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_detectedAllergens.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _detectedAllergens
                          .map(
                            (item) => Chip(
                              backgroundColor: Colors.red.shade50,
                              label: Text(
                                item.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (_result == 'Not Safe' && _recommendations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openRecommendationsPage,
                        icon: const Icon(Icons.recommend),
                        label: const Text('View Recommendations'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  ]
                ],
              ),
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

  Widget _nutritionRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: true,
      ),
      body: recommendations.isEmpty
          ? const Center(
              child: Text('No recommendations available'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (detectedAllergens.isNotEmpty) ...[
                  const Text(
                    'Detected allergens',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detectedAllergens
                        .map(
                          (item) => Chip(
                            backgroundColor: Colors.red.shade50,
                            label: Text(item.toString()),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                ...recommendations.map((rec) {
                  final imageUrl = rec['image_final'];
                  final nutrition = rec['nutrition'] ?? {};

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null &&
                              imageUrl.toString().trim().isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            rec['product_name']?.toString() ?? 'Unknown product',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (rec['brands'] != null &&
                              rec['brands'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              rec['brands'].toString(),
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                          if (rec['main_category'] != null &&
                              rec['main_category'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${rec['main_category']}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Text(
                            'Nutrition',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _nutritionRow('Energy', nutrition['energy_100g']),
                          _nutritionRow('Fat', nutrition['fat_100g']),
                          _nutritionRow('Carbs', nutrition['carbohydrates_100g']),
                          _nutritionRow('Sugars', nutrition['sugars_100g']),
                          _nutritionRow('Proteins', nutrition['proteins_100g']),
                          _nutritionRow('Salt', nutrition['salt_100g']),
                          _nutritionRow('Sodium', nutrition['sodium_100g']),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}