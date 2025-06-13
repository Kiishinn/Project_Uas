import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umkmproject/screens/editpost_screen.dart';

class DetailScreen extends StatefulWidget {
  final DocumentSnapshot document;

  const DetailScreen({super.key, required this.document});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController commentController = TextEditingController();

  List<Map<String, dynamic>> comments = [];
  bool isFavorite = false;
  int favoriteCount = 0;
  String? replyingTo; // ID of the comment being replied to
  String? username, phone;
  bool isReplying = false; // Track if we are replying to a comment

  @override
  void initState() {
    super.initState();
    fetchFavoriteData();
    fetchComments();
    fetchUserInfo();
  }

  Future<void> fetchFavoriteData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('umkms')
        .doc(widget.document.id)
        .get();

    final data = snapshot.data();
    if (data != null) {
      final favoriteBy = List<String>.from(data['favoriteBy'] ?? []);
      setState(() {
        isFavorite = favoriteBy.contains(userId);
        favoriteCount = data['favoriteCount'] ?? 0;
      });
    }
  }

  void toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance.collection('umkms').doc(widget.document.id);
    final snapshot = await docRef.get();
    final data = snapshot.data();

    List favoriteBy = data?['favoriteBy'] ?? [];

    if (isFavorite) {
      // If the UMKM is already in the user's favorites, remove it
      favoriteBy.remove(userId);

      // Remove the UMKM from the user's favorite collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .where('umkmId', isEqualTo: widget.document.id)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } else {
      // If the UMKM is not in the user's favorites, add it
      favoriteBy.add(userId);

      // Add the UMKM to the user's favorite collection
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').add({
        'umkmId': widget.document.id,
        'name': widget.document['name'],
        'jenis_usaha': widget.document['jenis_usaha'],
        'image_base64': widget.document['image_base64'],
      });
    }

    // Update the UMKM document with the new favorite list and count
    await docRef.update({
      'favoriteBy': favoriteBy,
      'favoriteCount': favoriteBy.length,
    });

    setState(() {
      isFavorite = !isFavorite;
      favoriteCount = favoriteBy.length;
    });
  }

  Future<void> fetchUserInfo() async {
    final userId = widget.document['uid'];
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData != null) {
      setState(() {
        username = userData['username'];
        phone = userData['phone'];
      });
    } else {
      setState(() {
        username = 'Tidak tersedia';
        phone = 'Tidak tersedia';
      });
    }
  }

  Future<void> fetchComments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('umkms')
        .doc(widget.document.id)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      comments = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<void> addComment({String? parentId}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final username = userData?['username'] ?? 'User';

    await FirebaseFirestore.instance
        .collection('umkms')
        .doc(widget.document.id)
        .collection('comments')
        .add({
      'text': text,
      'userId': user.uid,
      'username': username,
      'timestamp': FieldValue.serverTimestamp(),
      'parentId': parentId,
    });

    commentController.clear();
    setState(() {
      isReplying = false;
      replyingTo = null;
    });

    fetchComments();
  }

  List<Map<String, dynamic>> getReplies(String parentId) {
    return comments.where((c) => c['parentId'] == parentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final imageBase64 = data['image_base64'] ?? '';
    final image = imageBase64.isNotEmpty
        ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
        : Icon(Icons.image_not_supported, size: 100);

    final mainComments = comments.where((c) => c['parentId'] == null).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.white, 
      appBar: AppBar(
        title: Text('Detail UMKM', style: TextStyle(color: Color(0xFF6FCF97))),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black45 : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        actions: [
          if (FirebaseAuth.instance.currentUser?.uid == widget.document['uid'])
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(document: widget.document),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: image,
              ),
            ),
            SizedBox(height: 16),
            Text(data['name'] ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(data['jenis_usaha'] ?? '', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    data['alamat'] ?? 'Lokasi tidak tersedia',
                    style: TextStyle(fontSize: 14),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Informasi Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Username: $username', style: TextStyle(fontSize: 14)),
            SizedBox(height: 4),
            Text('No. HP: $phone', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['deskripsi'] ?? '-', style: TextStyle(fontSize: 14)),
            SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
                  onPressed: toggleFavorite,
                ),
                Text(isFavorite ? 'Favorited' : 'Add to Favorites'),
              ],
            ),
            SizedBox(height: 16),
            Text('Komentar:', style: TextStyle(fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: mainComments.length,
              itemBuilder: (context, index) {
                final comment = mainComments[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Komentar Utama
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child: Icon(Icons.person, color: Colors.white),
                            backgroundColor: Colors.grey[500],
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['username'] ?? 'User',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(comment['text'] ?? '', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.reply),
                            onPressed: () {
                              setState(() {
                                isReplying = true;
                                replyingTo = comment['id'];
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isReplying && replyingTo == comment['id'])
                      Padding(
                        padding: const EdgeInsets.only(left: 50.0),
                        child: Text(
                          "Membalas: ${comment['username']}",
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                        ),
                      ),
                    if (isReplying && replyingTo == comment['id'])
                      Padding(
                        padding: const EdgeInsets.only(left: 50.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: commentController,
                              decoration: InputDecoration(
                                labelText: 'Tulis Balasan...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () {
                                    addComment(parentId: replyingTo);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel),
                                  onPressed: () {
                                    setState(() {
                                      isReplying = false;
                                      replyingTo = null;
                                      commentController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (!isReplying || replyingTo != comment['id'])
                      ...getReplies(comment['id']).map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 50.0),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[900] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  child: Icon(Icons.person, color: Colors.white),
                                  backgroundColor: Colors.grey[500],
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reply['username'] ?? 'User',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(reply['text'] ?? '', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
            if (!isReplying)
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Tulis Komentar...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            if (!isReplying)
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  addComment();
                },
              ),
          ],
        ),
      ),
    );
  }
}
