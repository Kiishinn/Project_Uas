import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umkmproject/bottom_navbar.dart'; 
import 'package:umkmproject/screens/home_screen.dart'; 

class EditPostScreen extends StatefulWidget {
  final DocumentSnapshot document;

  const EditPostScreen({super.key, required this.document});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  String? _imageBase64;

  File? _imageFile;
  String? selectedJenisUsaha;

  final List<String> jenisUsahaList = [
    'Makanan & Minuman',
    'Pakaian',
    'Elektronik',
    'Furnitur',
    'Jasa',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.document['name'] ?? '';
    descriptionController.text = widget.document['deskripsi'] ?? '';
    locationController.text = widget.document['alamat'] ?? '';
    _imageBase64 = widget.document['image_base64'];
    selectedJenisUsaha = widget.document['jenis_usaha'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      final bytes = await _imageFile!.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _savePost() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final jenisUsaha = selectedJenisUsaha;
    final location = locationController.text.trim();

    if (name.isEmpty || description.isEmpty || jenisUsaha == null || location.isEmpty) return;

    await FirebaseFirestore.instance.collection('umkms').doc(widget.document.id).update({
      'name': name,
      'deskripsi': description,
      'jenis_usaha': jenisUsaha,
      'alamat': location,
      'image_base64': _imageBase64,
    });

    Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => BottomNavBar()),
    ModalRoute.withName('/HomeScreen'), 
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6FCF97),
        title: Text('Edit UMKM', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : _imageBase64 != null
                        ? MemoryImage(base64Decode(_imageBase64!))
                        : null,
                child: _imageFile == null
                    ? Icon(Icons.add_a_photo, color: Colors.grey[700], size: 40)
                    : null,
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama UMKM',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6FCF97), width: 2)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi UMKM',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6FCF97), width: 2)),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedJenisUsaha,
              onChanged: (String? newValue) {
                setState(() {
                  selectedJenisUsaha = newValue;
                });
              },
              decoration: InputDecoration(
                labelText: 'Jenis Usaha',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              items: jenisUsahaList.map((String jenis) {
                return DropdownMenuItem<String>(
                  value: jenis,
                  child: Text(jenis),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Lokasi',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6FCF97), width: 2)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6FCF97),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
