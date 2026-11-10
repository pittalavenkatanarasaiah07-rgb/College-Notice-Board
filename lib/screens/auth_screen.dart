import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;

  String selectedRole = 'student';

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? error;

    if (isLogin) {
      error = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: selectedRole,
      );
    } else {
      error = await _authService.registerStudent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rollNumber: _rollController.text.trim(),
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (error != null) {
      showMessage(error);
      return;
    }

    if (!isLogin) {
      setState(() {
        isLogin = true;
        selectedRole = 'student';
      });

      _passwordController.clear();

      showMessage(
        'Verification email sent! Please open your email and verify your account before login.',
      );

      return;
    }

    showMessage('Login successful!');

    final destination = selectedRole == 'admin'
        ? const AdminDashboard()
        : const StudentDashboard();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),

      appBar: AppBar(
        title: const Text(
          'College Notice Board',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            child: Padding(
              padding: const EdgeInsets.all(22),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    const Icon(
                      Icons.school,
                      size: 75,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isLogin
                          ? 'Welcome Back!'
                          : 'Student Registration',

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isLogin
                          ? 'Login to continue'
                          : 'Create your student account',

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Student Name

                    if (!isLogin) ...[

                      TextFormField(
                        controller: _nameController,

                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Roll Number

                      TextFormField(
                        controller: _rollController,

                        decoration: const InputDecoration(
                          labelText: 'Roll Number',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter roll number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                    ],

                    // Email

                    TextFormField(
                      controller: _emailController,

                      keyboardType: TextInputType.emailAddress,

                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email address';
                        }

                        if (!_authService.isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password

                    TextFormField(
                      controller: _passwordController,

                      obscureText: obscurePassword,

                      decoration: InputDecoration(
                        labelText: 'Password',

                        prefixIcon: const Icon(Icons.lock),

                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),

                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        border: const OutlineInputBorder(),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }

                        if (!isLogin &&
                            !_authService.isStrongPassword(value)) {
                          return 'Use 8+ chars, uppercase, lowercase, number and special character';
                        }

                        return null;
                      },
                    ),

                    if (!isLogin) ...[

                      const SizedBox(height: 10),

                      const Text(
                        'Password requirements:\n'
                            '• Minimum 8 characters\n'
                            '• One uppercase letter (A-Z)\n'
                            '• One lowercase letter (a-z)\n'
                            '• One number (0-9)\n'
                            '• One special character (!@#\$)',

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Login Role

                    if (isLogin)
                      DropdownButtonFormField<String>(
                        value: selectedRole,

                        decoration: const InputDecoration(
                          labelText: 'Login As',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),

                        items: const [

                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),

                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),

                        ],

                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),

                    const SizedBox(height: 25),

                    // Submit Button

                    SizedBox(
                      height: 52,

                      child: ElevatedButton(
                        onPressed: isLoading ? null : submit,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        child: isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          isLogin ? 'LOGIN' : 'REGISTER',

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Switch Login / Registration

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        setState(() {
                          isLogin = !isLogin;
                          selectedRole = 'student';
                          obscurePassword = true;
                        });

                        _formKey.currentState?.reset();
                      },

                      child: Text(
                        isLogin
                            ? "New Student/Admin? Register here"
                            : "Already registered? Login",

                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
