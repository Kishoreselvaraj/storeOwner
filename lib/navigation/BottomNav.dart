import 'package:flutter/material.dart';
import '../screens/Home/HomPage.dart';
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

  // Nested navigator for the Home tab
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
    setState(() => _selectedIndex = index);
  }


  Future<bool> _onWillPop() async {
    if (_selectedIndex == 0) {
      final popped = await (_homeKey.currentState?.maybePop() ?? Future.value(false));
      if (popped) return false;
      return true;
    } else {
      setState(() => _selectedIndex = 0);
      return false;
    }
  }

  // Home tab hosts its own navigator so content can change while the bar stays.
  Widget _buildHomeNavigator() {
    final key = GlobalKey<NavigatorState>();
    return KeyedSubtree(
      key: UniqueKey(),                 // new subtree every build
      child: Navigator(
        key: key,                       // new navigator state
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => HomePage(
                  onAddProduct: () => key.currentState?.pushNamed('/product-list'),
                ),
              );
            case '/product-list':
              return MaterialPageRoute(builder: (_) => const ProductListPage());
          }
          return null;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF8D29);
    const inactiveColor = Color(0xFF82838B);

    final barHeight = SizeHelper.byHeight(context, 88);
    final iconW = SizeHelper.byWidth(context, 25);
    final iconH = SizeHelper.byHeight(context, 25);

    // Use IndexedStack so each tab preserves state
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
