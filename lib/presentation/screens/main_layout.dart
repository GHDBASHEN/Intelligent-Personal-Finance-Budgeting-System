import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/chatbot_widget.dart';

// Create a global key outside the class that can be accessed from anywhere
final GlobalKey<ScaffoldState> mainLayoutScaffoldKey = GlobalKey<ScaffoldState>();

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: mainLayoutScaffoldKey,
      drawer: Drawer(
        child: Container(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          child: Column(
            children: [
              // Yellowish/Orange header section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? Icon(Icons.person, size: 45, color: Colors.orange.shade600)
                              : null,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          user?.username ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Menu items
              _buildDrawerItem(
                icon: Icons.person_outline,
                title: 'Profile',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/dashboard');
                },
              ),
              _buildDrawerItem(
                icon: Icons.list_alt_outlined,
                title: 'Transactions',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/transactions');
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                isLogout: true,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.child,
          const ChatbotWidget(), // Add chatbot to all screens
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isLogout 
            ? Colors.red 
            : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout 
              ? Colors.red 
              : (isDarkMode ? Colors.white : Colors.grey.shade800),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      hoverColor: isDarkMode ? Colors.white12 : Colors.grey.shade200,
      splashColor: isDarkMode ? Colors.white10 : Colors.grey.shade100,
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}