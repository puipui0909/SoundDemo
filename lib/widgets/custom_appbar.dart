import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/theme_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final Widget? action;
  final String title;

  const CustomAppBar({super.key, this.onBack, this.action, required this.title});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      // Xoá hết stack và đưa về màn hình signin
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/signin',
            (route) => false,
      );
    } catch (e) {
      debugPrint("Lỗi khi đăng xuất: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng xuất thất bại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if(onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
            else if(action != null)
              action!,
            const Spacer(),
            const SizedBox(width: 70,),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),
            const Spacer(flex: 2),

            /// Nút menu "..."
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final themeNotifier =
                Provider.of<ThemeNotifier>(context, listen: false);

                if (value == 'theme') {
                  final isDark = themeNotifier.themeMode == ThemeMode.dark;
                  themeNotifier.setTheme(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                } else if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              itemBuilder: (context) {
                final themeNotifier =
                Provider.of<ThemeNotifier>(context, listen: false);
                final isDark = themeNotifier.themeMode == ThemeMode.dark;

                return [
                  PopupMenuItem(
                    value: 'theme',
                    child: Text(
                      isDark
                          ? "Chuyển sang Light Mode"
                          : "Chuyển sang Dark Mode",
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text("Đăng xuất"),
                  ),
                ];
              },
            ),
          ],
        ),
      );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
