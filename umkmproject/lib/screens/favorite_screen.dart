import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'detail_screen.dart';  // Pastikan DetailScreen diimport

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String searchQuery = '';
  late Stream<QuerySnapshot> favoriteStream;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // Stream data favorit pengguna
      favoriteStream = FirebaseFirestore.instance
          .collection('users') // Koleksi users
          .doc(userId)
          .collection('favorites') // Koleksi favorit untuk masing-masing pengguna
          .snapshots();
    } else {
      // Jika tidak ada pengguna yang login, kita tampilkan pesan error
      favoriteStream = Stream.empty(); // Menggunakan Stream kosong
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, // Background color based on the theme
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Favorite',
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
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.grey[87], // Background color based on the theme
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari favorit...',
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

            // Daftar item favorit
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: favoriteStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("Belum ada favorit"),
                    );
                  }

                  final filteredFavorites = snapshot.data!.docs.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final favorite = filteredFavorites[index];
                      final umkmId = favorite['umkmId'];  // Ambil umkmId dari koleksi favorites
                      
                      // Ambil data UMKM dari koleksi `umkms` untuk mendapatkan deskripsi
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('umkms').doc(umkmId).get(),
                        builder: (context, umkmSnapshot) {
                          if (umkmSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!umkmSnapshot.hasData || !umkmSnapshot.data!.exists) {
                            return ListTile(title: Text('UMKM tidak ditemukan'));
                          }

                          final umkmData = umkmSnapshot.data!.data() as Map<String, dynamic>;
                          final name = umkmData['name'] ?? 'Nama tidak tersedia';
                          final deskripsi = umkmData['deskripsi'] ?? 'Deskripsi tidak tersedia';
                          final imageBase64 = umkmData['image_base64'] ?? '';
                          final imageUrl = imageBase64.isNotEmpty
                              ? Image.memory(base64Decode(imageBase64), width: 50, height: 50, fit: BoxFit.cover)
                              : Icon(Icons.image_not_supported, size: 50);

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                            leading: imageUrl,
                            title: Text(name),
                            subtitle: Text(deskripsi),
                            trailing: Icon(Icons.favorite, color: Colors.redAccent),
                            onTap: () {
                              // Navigasi ke DetailScreen dan kirim DocumentSnapshot UMKM
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(document: umkmSnapshot.data!),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
