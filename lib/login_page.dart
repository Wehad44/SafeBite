import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

  Future<List<String>> _loadUserAllergies(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null) return [];

    final raw = data['allergies'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    return [];
  }

  Future<void> _goToSelectionThenHome(
    User user, {
    List<String> initialAllergies = const [],
  }) async {
    final selectedAllergies = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AllergySelectionPage(
          userId: user.uid,
          initialAllergies: initialAllergies,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          userAllergens: selectedAllergies ?? initialAllergies,
        ),
      ),
    );
  }

  Future<void> signUp() async {
    setState(() => isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully.")),
      );

      await _goToSelectionThenHome(credential.user!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signIn() async {
    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = credential.user!;
      final allergies = await _loadUserAllergies(user.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful.")),
      );

      if (allergies.isEmpty) {
        await _goToSelectionThenHome(user);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userAllergens: allergies,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
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
                    isPasswordHidden
                        ? Icons.visibility
                        : Icons.visibility_off,
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
              onPressed: isLoading ? null : signIn,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Sign In"),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : signUp,
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}