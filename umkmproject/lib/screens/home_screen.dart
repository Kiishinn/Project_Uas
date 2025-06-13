import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:umkmproject/screens/posting_screen.dart';
import 'package:umkmproject/screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  Stream<QuerySnapshot> umkmStream =
      FirebaseFirestore.instance
          .collection('umkms')
          .orderBy('created_at', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.white, // Background color based on the theme
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Home',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Background color based on the theme
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Search Field
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.grey[100], // Background color based on the theme
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari UMKM...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(height: 12),

            // GridView
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: umkmStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("Belum ada UMKM yang diposting"),
                    );
                  }

                  final filteredUmkm = snapshot.data!.docs.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  return GridView.builder(
                    itemCount: filteredUmkm.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final umkm = filteredUmkm[index];
                      final name = umkm['name'] ?? '';
                      final jenisUsaha = umkm['jenis_usaha'] ?? '';
                      final fullAddress = umkm['alamat'] ?? '';
                      final imageBase64 = umkm['image_base64'] ?? '';

                      final location = fullAddress.split(',').length >= 3
                          ? fullAddress.split(',')[3].trim()
                          : fullAddress;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(document: umkm),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, // Background color based on the theme
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: imageBase64.isNotEmpty
                                    ? AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.memory(
                                          base64Decode(imageBase64),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Background color based on the theme
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      jenisUsaha,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // Background color based on the theme
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.green[600],
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // FloatingActionButton untuk posting
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF6FCF97),
        onPressed: () {
          // Navigasi ke form posting UMKM
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostingScreen()),
          );
        },
        child: Icon(Icons.add_business, size: 28),  // Ikon bisnis
        elevation: 6,
      ),
    );
  }
}
