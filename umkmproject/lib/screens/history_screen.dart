import 'package:flutter/material.dart';

class HistoryPostScreen extends StatefulWidget {
  const HistoryPostScreen({super.key});

  @override
  State<HistoryPostScreen> createState() => _HistoryPostScreenState();
}

class _HistoryPostScreenState extends State<HistoryPostScreen> {
  @override
  Widget build(BuildContext context) {
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
                  'History Post',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: Colors.black87,
                        size: 30,
                      ),
                      onPressed: () {
                        // TODO: Navigasi ke halaman notifikasi
                      },
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '3', // jumlah notifikasi (dummy)
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
