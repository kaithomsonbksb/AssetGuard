import 'package:flutter/material.dart';

/// loginscreen widget that provides user authentication interface
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// state class that manages the login form and form validation
class _LoginScreenState extends State<LoginScreen> {
  // form key
  final _formKey = GlobalKey<FormState>();

  // controllers to capture user input from text fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // flag track login button being processing
  bool _isLoading = false;

  // flag to toggle password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// validates and processes the login attempt
  void _handleLogin() {
    // check if form is valid based on validators
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // simulate auth delay 
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });

        // show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to jobs screen after successful login
        Navigator.of(context).pushReplacementNamed('/jobs');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar at the top of the screen
      appBar: AppBar(
        title: const Text('AssetGuard Login'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Allows scrolling if content exceeds screen height
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacer at the top for visual balance
                const SizedBox(height: 40),

                // Logo or title section
                Center(
                  child: Text(
                    'AssetGuard',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Center(
                  child: Text(
                    'Asset Management System',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
                const SizedBox(height: 48),

                // Username/Email input field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username or Email',
                    hintText: 'Enter your username or email',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Validator to check if field is empty
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username or email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password input field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  // Hide password characters by default
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    // Suffix icon to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Validator to check if field is empty and minimum length
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset feature coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button with loading state
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  // Disable button while loading
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Sign up link for new users
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to sign up screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign up feature coming soon!'),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
