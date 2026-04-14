import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllergySelectionPage extends StatefulWidget {
  final String userId;
  final List<String> initialAllergies;

  const AllergySelectionPage({
    super.key,
    required this.userId,
    this.initialAllergies = const [],
  });

  @override
  State<AllergySelectionPage> createState() => _AllergySelectionPageState();
}

class _AllergySelectionPageState extends State<AllergySelectionPage> {
  final Map<String, bool> allergies = {
    'milk_dairy': false,
    'peanut': false,
    'tree_nut': false,
    'egg': false,
    'gluten_cereals': false,
    'soy': false,
    'fish': false,
    'shellfish': false,
    'sesame': false,
  };

  @override
  void initState() {
    super.initState();

    for (final allergen in widget.initialAllergies) {
      if (allergies.containsKey(allergen)) {
        allergies[allergen] = true;
      }
    }
  }

  String _label(String key) {
    switch (key) {
      case 'milk_dairy':
        return 'Milk / Dairy';
      case 'peanut':
        return 'Peanut';
      case 'tree_nut':
        return 'Tree Nut';
      case 'egg':
        return 'Egg';
      case 'gluten_cereals':
        return 'Gluten / Cereals';
      case 'soy':
        return 'Soy';
      case 'fish':
        return 'Fish';
      case 'shellfish':
        return 'Shellfish';
      case 'sesame':
        return 'Sesame';
      default:
        return key;
    }
  }

  Future<void> _saveAllergies() async {
    final List<String> selectedAllergies = allergies.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
      {
        'allergies': selectedAllergies,
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;
    Navigator.pop(context, selectedAllergies);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Allergies'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: allergies.keys.map((item) {
                return CheckboxListTile(
                  title: Text(_label(item)),
                  value: allergies[item],
                  onChanged: (value) {
                    setState(() {
                      allergies[item] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAllergies,
                child: const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}