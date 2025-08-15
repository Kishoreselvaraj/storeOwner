import 'package:flutter/material.dart';
import '../screens/Home/HomPage.dart';
import '../screens/Chat/ChatPage.dart';
import '../screens/Profile/ProfilePage.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  // Navigation items data
  final List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'screen': const HomePage(),
    },
    {
      'label': 'Chat',
      'icon': Icons.chat_bubble_outline,
      'activeIcon': Icons.chat_bubble,
      'screen': const ChatPage(),
    },
    {
      'label': 'Profile',
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'screen': const ProfilePage(),
    },
  ];

  void _onTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF8D29);         // matches your last code
    const inactiveColor = Color(0xFF82838B);
    const barHeight = 88.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          // Keep state of each tab intact
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _navItems.map((e) => e['screen'] as Widget).toList(),
            ),
          ),

          // Custom Bottom Bar with InkWell
          SafeArea(
            top: false,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final bool isActive = _selectedIndex == index;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onTap(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon (switches to activeIcon when selected)
                              Icon(
                                isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                                size: 26,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                              const SizedBox(height: 6),
                              // Label
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive ? activeColor : inactiveColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
