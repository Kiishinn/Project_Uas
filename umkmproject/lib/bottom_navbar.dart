import 'package:flutter/material.dart';
import 'package:umkmproject/screens/home_screen.dart';
import 'package:umkmproject/screens/favorite_screen.dart';
import 'package:umkmproject/screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  // Daftar screens yang akan ditampilkan berdasarkan tab yang dipilih
  final List<Widget> _screens = [
    HomeScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  // Daftar ikon untuk setiap tab
  final List<IconData> _iconList = [
    Icons.home,
    Icons.favorite,
    Icons.person,
  ];

  // Daftar label untuk setiap tab
  final List<String> _labels = [
    "Home", "Favorite", "Profile"
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Mengubah tab yang dipilih
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Menampilkan screen berdasarkan tab yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,  // Menyimpan tab yang dipilih
        onTap: _onItemTapped,  // Fungsi yang dipanggil ketika tab dipilih
        items: [
          BottomNavigationBarItem(
            icon: Icon(_iconList[0]),
            label: _labels[0], // Label di bawah ikon
          ),
          BottomNavigationBarItem(
            icon: Icon(_iconList[1]),
            label: _labels[1], // Label di bawah ikon
          ),
          BottomNavigationBarItem(
            icon: Icon(_iconList[2]),
            label: _labels[2], // Label di bawah ikon
          ),
        ],
        backgroundColor: Colors.white,  // Warna background navbar
        selectedItemColor: Color(0xFF6FCF97),  // Warna ikon yang dipilih
        unselectedItemColor: Colors.grey[600],  // Warna ikon yang tidak dipilih
        type: BottomNavigationBarType.fixed,  // Layout tetap, bukan yang shifting
        iconSize: 30,  // Ukuran ikon
        elevation: 8,  // Memberikan shadow pada navbar
        showSelectedLabels: true,  // Menampilkan label pada ikon yang dipilih
        showUnselectedLabels: true,  // Menampilkan label pada ikon yang tidak dipilih
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),  // Gaya untuk label yang dipilih
        unselectedLabelStyle: TextStyle(fontSize: 12),  // Gaya untuk label yang tidak dipilih
      ),
    );
  }
}
