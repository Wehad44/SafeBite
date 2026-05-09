import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final List<String> userAllergens;

  const HomePage({
    super.key,
    this.userAllergens = const [],
  });

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

  late List<String> _userAllergens;

  final List<String> _categoryOptions = [
    'Chocolate',
    'Dairy',
    'Cookies & Snacks',
    'Cereal',
    'Drinks',
    'Desserts',
    'Bread & Bakery',
    'Sauces',
  ];

  String? _selectedCategory;

  final String apiUrl = 'http://10.0.2.2:5000/analyze';

  @override
  void initState() {
    super.initState();
    _userAllergens = List<String>.from(widget.userAllergens);
  }

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

  Future<void> _openProfilePage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedAllergies = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AllergySelectionPage(
          userId: user.uid,
          initialAllergies: _userAllergens,
        ),
      ),
    );

    if (updatedAllergies != null) {
      setState(() {
        _userAllergens = updatedAllergies;
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

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      setState(() {
        _result = 'Please select a category first';
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
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );

      request.fields['user_allergens'] = jsonEncode(_userAllergens);
      request.fields['input_main_category'] = _selectedCategory ?? '';

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print(data);

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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

  Widget _allergyChip(String text) {
    return Chip(
      backgroundColor: Colors.blue.shade50,
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
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
        actions: [
          IconButton(
            onPressed: _openProfilePage,
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_userAllergens.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _userAllergens.map(_allergyChip).toList(),
                ),
              ),
            if (_userAllergens.isNotEmpty) const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Product Category',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _categoryOptions.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 12),

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
                            Icon(Icons.image_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No image selected',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (_result == 'Not Safe') ...[
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
                    ),
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

  String cleanText(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    final regex = RegExp(r"'text':\s*'([^']*)'");
    final matches = regex.allMatches(text).map((m) => m.group(1) ?? '').toList();

    if (matches.isNotEmpty) {
      return matches.firstWhere(
        (t) => RegExp(r'[a-zA-Z]').hasMatch(t),
        orElse: () => matches.first,
      );
    }

    return text
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .trim();
  }

  Widget _nutritionRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
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
              children: recommendations.map((rec) {
                final imageUrl = rec['image_final'];
                final nutrition = rec['nutrition'] ?? {};
                final productName = cleanText(rec['product_name']);
                final ingredients = cleanText(rec['ingredients_text']);

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
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullImagePage(
                                    imageUrl: imageUrl.toString(),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                imageUrl.toString(),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text(
                          productName.isEmpty ? 'Unknown product' : productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (rec['brands'] != null &&
                            rec['brands'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            cleanText(rec['brands']),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        if (rec['main_category'] != null &&
                            rec['main_category'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Category: ${cleanText(rec['main_category'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ingredients.isEmpty
                              ? 'No ingredients available'
                              : ingredients,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'Nutrition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
              }).toList(),
            ),
    );
  }
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Product Image'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


