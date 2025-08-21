import 'package:flutter/material.dart';
import '../screens/Home/HomPage.dart'; // Ensure this path/class name matches your file (HomePage)
import '../screens/Chat/ChatPage.dart';
import '../screens/Profile/ProfilePage.dart';
import '../screens/Home/ProductListPage.dart';
import '../utils/SizeHelper.dart';

class NavItem {
  final String label;
  final String icon;
  final String activeIcon;
  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  // Persistent nested navigator key for Home tab
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();

  static const List<NavItem> _navItems = [
    NavItem(
      label: 'Home',
      icon: 'assets/bottomnav/home.png',
      activeIcon: 'assets/bottomnav/home1.png',
    ),
    NavItem(
      label: 'Chat',
      icon: 'assets/bottomnav/chat.png',
      activeIcon: 'assets/bottomnav/chat1.png',
    ),
    NavItem(
      label: 'Profile',
      icon: 'assets/bottomnav/profile.png',
      activeIcon: 'assets/bottomnav/profile1.png',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precaching can run after first build; guard with mounted for safety in async rebuilds
    if (!mounted) return;
    for (final item in _navItems) {
      precacheImage(AssetImage(item.icon), context);
      precacheImage(AssetImage(item.activeIcon), context);
    }
  }

  void _onTap(int index) {
    // if (index == _selectedIndex) {
    //   setState(() => _selectedIndex = 4);
    //   setState(() => _selectedIndex = index);
    // }
    // Optional: tapping the active Home tab pops to its root
    if (index == _selectedIndex && index == 0) {
      _homeKey.currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _selectedIndex = index);
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 0) {
      // Try to pop the nested Home navigator first
      final popped = await (_homeKey.currentState?.maybePop() ?? Future.value(false));
      if (popped) return false; // consumed by inner navigator
      return true;              // let system back close the app
    } else {
      // Go back to Home tab instead of exiting
      setState(() => _selectedIndex = 0);
      return false;
    }
  }

  // Home tab hosts its own navigator so content can change while the bar stays.
  Widget _buildHomeNavigator() {
    return Navigator(
      key: _homeKey, // ✅ use the persistent key
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => HomePage(
                onAddProduct: () => _homeKey.currentState?.pushNamed('/product-list'),
              ),
            );
          case '/product-list':
            return MaterialPageRoute(builder: (_) => const ProductListPage());
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF8D29);
    const inactiveColor = Color(0xFF82838B);

    final barHeight = SizeHelper.byHeight(context, 88);
    final iconW = SizeHelper.byWidth(context, 25);
    final iconH = SizeHelper.byHeight(context, 25);

    final screens = <Widget>[
      _buildHomeNavigator(),
      const ChatPage(),
      const ProfilePage(),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                height: barHeight,
                color: Colors.white,
                child: Row(
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isActive = _selectedIndex == index;

                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onTap(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image(
                                  image: AssetImage(isActive ? item.activeIcon : item.icon),
                                  width: iconW,
                                  height: iconH,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                    color: isActive ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
