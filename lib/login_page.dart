import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // عشان HomePage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isPasswordHidden = true;

  Future<void> signUp() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AllergySelectionPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful.")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(), // هذه صفحتك الحالية
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: password,
              obscureText: isPasswordHidden,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await signIn();
              },
              child: const Text("Sign In"),
            ),

            ElevatedButton(
              onPressed: () async {
                await signUp();
              },
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}

class AllergySelectionPage extends StatefulWidget {
  const AllergySelectionPage({super.key});

  @override
  State<AllergySelectionPage> createState() => _AllergySelectionPageState();
}

class _AllergySelectionPageState extends State<AllergySelectionPage> {
  Map<String, bool> allergies = {
    "Milk": false,
    "Peanuts": false,
    "Eggs": false,
    "Gluten": false,
    "Seafood": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Allergies")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: allergies.keys.map((item) {
                return CheckboxListTile(
                  title: Text(item),
                  value: allergies[item],
                  onChanged: (value) {
                    setState(() {
                      allergies[item] = value!;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user != null) {
                List selectedAllergies = allergies.entries
                    .where((e) => e.value == true)
                    .map((e) => e.key)
                    .toList();

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({'allergies': selectedAllergies});

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }
}
