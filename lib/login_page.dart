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

  String? emailError;
  String? passwordError;

  bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@(gmail|hotmail|outlook|yahoo)\.com$',
    ).hasMatch(email);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> signUp() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    String userEmail = email.text.trim();
    String userPassword = password.text.trim();

    if (!isValidEmail(userEmail)) {
      setState(() {
        emailError = "Enter a valid email";
      });
      return;
    }

    // Validation
    if (userEmail.isEmpty) {
      setState(() {
        emailError = "Email is required";
      });
      return;
    }

    if (!userEmail.contains("@")) {
      setState(() {
        emailError = "Invalid email";
      });
      return;
    }

    if (userPassword.isEmpty) {
      setState(() {
        passwordError = "Password is required";
      });
      return;
    }

    if (userPassword.length < 6) {
      setState(() {
        passwordError = "At least 6 characters";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AllergySelectionPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          emailError = "This email is already registered";
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          passwordError = "Weak password";
        });
      } else {
        setState(() {
          emailError = "Sign up failed";
        });
      }
    }
  }

  Future<void> signIn() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    String userEmail = email.text.trim();
    String userPassword = password.text.trim();

    if (!isValidEmail(userEmail)) {
      setState(() {
        emailError = "Enter a valid email";
      });
      return;
    }

    if (userEmail.isEmpty) {
      setState(() {
        emailError = "Email is required";
      });
      return;
    }

    if (!userEmail.contains("@")) {
      setState(() {
        emailError = "Invalid email";
      });
      return;
    }

    if (userPassword.isEmpty) {
      setState(() {
        passwordError = "Password is required";
      });
      return;
    }

    if (userPassword.length < 6) {
      setState(() {
        passwordError = "At least 6 characters";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          emailError = "No account found";
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          passwordError = "Incorrect password";
        });
      } else {
        setState(() {
          emailError = "Login failed";
        });
      }
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
              decoration: InputDecoration(
                labelText: "Email",
                errorText: emailError,
              ),
            ),

            TextField(
              controller: password,
              obscureText: isPasswordHidden,
              decoration: InputDecoration(
                labelText: "Password",
                errorText: passwordError,
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

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () {
                    signUp(); // يسوي تسجيل مباشرة
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
