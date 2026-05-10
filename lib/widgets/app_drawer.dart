import 'package:bareed/screens/devApp.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/account_settings_page.dart';
import '../screens/offices_screen.dart';

class AppDrawer extends StatefulWidget {
  final Function(String)? onCategorySelected;
  final VoidCallback? onProfileUpdated;
  const AppDrawer({super.key, this.onCategorySelected, this.onProfileUpdated});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryDarkBlue),
            accountName: Text(
              _user?.branchName ?? 'جاري التحميل...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('كود: ${_user?.branchCode ?? '...'}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.settings, 'إعدادات الحساب', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsPage(),
                    ),
                  ).then((_) {
                    widget.onProfileUpdated?.call();
                  });
                }),

                _buildDrawerItem(Icons.code, 'المطورون', () {
                 
                  Navigator.pop(context);
                   Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => DevApp()));
                }),

                const Divider(),
                _buildDrawerItem(Icons.all_inbox, 'كل البريد (All Mail)', () {
                  Navigator.pop(context);
                  widget.onCategorySelected?.call('All Mail');
                }),
                _buildDrawerItem(Icons.business, 'الفروع والمكاتب', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfficesScreen(),
                    ),
                  );
                }),
                _buildDrawerItem(Icons.move_to_inbox, 'الواردة', () {
                  Navigator.pop(context);
                  widget.onCategorySelected?.call('Inbox');
                }),
                _buildDrawerItem(Icons.outbox, 'المرسلة', () {
                  Navigator.pop(context);
                  widget.onCategorySelected?.call('Sent');
                }),
                _buildDrawerItem(Icons.cancel_outlined, 'الملغية', () {
                  Navigator.pop(context);
                  widget.onCategorySelected?.call('Cancelled');
                }),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(Icons.logout, 'تسجيل الخروج', () async {
            Navigator.pop(context);
            await _authService.logout();
            // App state handles navigation
          }, isLogout: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : AppTheme.primaryDarkBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : AppTheme.primaryDarkBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
