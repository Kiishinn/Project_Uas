import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:umkmproject/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;
  String _imageBase64 = '';
  String _originalImageBase64 = '';  // Untuk menyimpan gambar asli
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      setState(() {
        _nameController.text = userData?['username'] ?? '';
        _emailController.text = userData?['email'] ?? '';
        _phoneController.text = userData?['phone'] ?? '';
        _imageBase64 = userData?['image_base64'] ?? '';
        _originalImageBase64 = _imageBase64;  // Menyimpan gambar asli
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);  // Menyimpan file yang dipilih
      });
      await _compressAndEncodeImage();
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_imageFile == null) return;

    final bytes = await _imageFile!.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    img.Image resized = img.copyResize(image, width: 400);
    List<int> jpg = img.encodeJpg(resized, quality: 70);

    if (jpg.length > 900 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ukuran gambar terlalu besar!')));
      return;
    }

    setState(() {
      _imageBase64 = base64Encode(jpg);  // Menyimpan gambar sebagai Base64 untuk simpan ke Firebase
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua kolom harus diisi!')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'image_base64': _imageBase64,  // Menyimpan foto profil dalam Base64 ke Firestore
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil berhasil diperbarui!')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Fungsi untuk membatalkan perubahan (kembalikan gambar awal)
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _imageBase64 = _originalImageBase64;  // Mengembalikan gambar ke gambar awal
      _imageFile = null;  // Menghapus gambar sementara jika dibatalkan
    });
  }

  Widget _buildProfileImage(String? imageBase64) {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover, width: 120, height: 120); // Menampilkan gambar yang dipilih
    } else if (imageBase64 != null && imageBase64.isNotEmpty) {
      return Image.memory(base64Decode(imageBase64), fit: BoxFit.cover, width: 120, height: 120); // Gambar dari Firebase
    } else {
      return Icon(Icons.person, size: 60, color: Colors.grey[400]);
    }
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();  // Melakukan logout dari Firebase
      // Mengarahkan pengguna ke halaman login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Arahkan langsung ke LoginScreen
        (Route<dynamic> route) => false,  // Hapus semua rute sebelumnya
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan saat logout')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profil',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    // Navigasi ke halaman notifikasi jika diperlukan
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Tidak ada data'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? '';
          final email = userData['email'] ?? '';
          final phone = userData['phone'] ?? '';
          final imageBase64 = userData['image_base64'] ?? '';

          _nameController.text = username;
          _emailController.text = email;
          _phoneController.text = phone;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.green,
                        child: ClipOval(
                          child: _buildProfileImage(imageBase64),  // Menampilkan gambar profil yang dipilih atau yang sudah ada
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('Email: $email', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          SizedBox(height: 5),
                          Text('No. HP: $phone', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Divider(color: Colors.grey[300]),
                SizedBox(height: 20),
                if (_isEditing) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Nomor Telepon', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Simpan Perubahan'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _cancelEdit,  // Fungsi untuk membatalkan perubahan
                    child: Text('Batal'),
                  ),
                ] else ...[
                  // Tombol Edit Profil
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6FCF97),
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Tombol Logout
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
