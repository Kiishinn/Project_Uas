import 'package:flutter/material.dart';
import 'package:umkmproject/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool obscurePassword = true;
  bool _isLoading = false;

  String? _errorEmail;
  String? _errorPassword;
  String? _errorName;
  String? _errorUsername;
  String? _errorPhone;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _signUp() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();
    String username = usernameController.text.trim();
    String phone = phoneController.text.trim();

    setState(() {
      _errorEmail = null;
      _errorPassword = null;
      _errorName = null;
      _errorUsername = null;
      _errorPhone = null;
    });
    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        _errorEmail = 'Email Tidak Boleh kosong!';
      });
      hasError = true;
    } else if (!RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(email)) {
      setState(() {
        _errorEmail = 'Format Email tidak valid!';
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        _errorPassword = 'Password Tidak Boleh kosong!';
      });
      hasError = true;
    } else if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*()<>,.?"/:;]'))) {
      setState(() {
        _errorPassword =
            'Minimal 8 karakter, terdiri huruf besar, kecil, angka, simbol';
      });
      hasError = true;
    }

    if (name.isEmpty) {
      setState(() {
        _errorName = 'Nama tidak boleh kosong!';
      });
      hasError = true;
    }

    if (username.isEmpty) {
      setState(() {
        _errorUsername = 'Username Tidak Boleh kosong!';
      });
      hasError = true;
    }

    if (phone.isEmpty) {
      setState(() {
        _errorPhone = 'Nomor hp Tidak Boleh kosong!';
      });
      hasError = true;
    } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        _errorPhone = 'Nomor hp hanya boleh mengandung angka!';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // Panggil fungsi signUpWithEmailPassword dengan data tambahan
      User? user = await _authService.signUpWithEmailPassword(
        email,
        password,
        name,
        username,
        phone,
      );

      if (user != null) {
        // Pendaftaran berhasil, navigasi ke LoginScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/LoginScreen');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat pendaftaran.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar. Gunakan email lain.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      // Tangani error lain yang mungkin terjadi saat menyimpan ke Firestore
      print("Error during sign up process: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan yang tidak terduga: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hentikan loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.white, // Background color based on the theme
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo bulat hijau
              Container(
                margin: EdgeInsets.only(top: 30),
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: Color(0xFF6FCF97), // Hijau muda
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logoumkm.png',
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 20),

              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Bergabunglah bersama kami dan bagikan usaha anda!",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              SizedBox(height: 30),

              // Nama Lengkap
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Nama Lengkap",
                  errorText: _errorName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person, color: Color(0xFF6FCF97)),
                ),
              ),
              SizedBox(height: 20),

              // Username
              TextField(
                controller: usernameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Username",
                  errorText: _errorUsername,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.account_circle,
                    color: Color(0xFF6FCF97),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Nomor Telepon
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Nomor Telepon",
                  errorText: _errorPhone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF6FCF97)),
                ),
              ),
              SizedBox(height: 20),

              // Email
              TextField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Email",
                  errorText: _errorEmail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email, color: Color(0xFF6FCF97)),
                ),
              ),
              SizedBox(height: 20),

              // Password
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Password",
                  errorText: _errorPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF6FCF97)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF6FCF97),
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Tombol Daftar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FCF97),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(
                            // Tampilkan loading indicator
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : const Text(
                            "Daftar",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
                                  offset: Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                ),
              ),
              SizedBox(height: 20),

              // Sudah punya akun?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Sudah punya akun? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/LoginScreen');
                    },
                    child: Text(
                      "Masuk",
                      style: TextStyle(
                        color: Color(0xFF6FCF97),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
