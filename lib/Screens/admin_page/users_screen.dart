import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart';
import '../../service/user_service.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/list.dart';
import '../main_page/profile_screen.dart';

class UsersScreen extends StatelessWidget {
  final UserService _userService = UserService();

  UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(title: 'USERS'),
      body: FutureBuilder<List<AppUser>>(
        future: _fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text("Chưa có người dùng nào"));
          }

          return ListWidget<AppUser>(
            items: users,
            getTitle: (user) =>
            user.fullName.isNotEmpty ? user.fullName : (user.email ?? 'No name'),
            // 🔹 Ưu tiên avatarUrl nếu có, fallback sang avatar tạm từ ui-avatars
            getCoverUrl: (user) {
              if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
                return user.avatarUrl!;
              } else {
                final name = Uri.encodeComponent(
                    user.fullName.isNotEmpty ? user.fullName : (user.email ?? "User"));
                return 'https://ui-avatars.com/api/?name=$name';
              }
            },
            onTap: (context, user) {
              final isCurrentUser =
                  currentUser != null && currentUser.id == user.id;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    userId: user.id,
                    isAdmin: currentUser != null &&
                        currentUser.id == user.id &&
                        user.role == 'admin',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<AppUser>> _fetchAllUsers() async {
    final supabase = _userService.supabase;
    final response = await supabase
        .from('users')
        .select('id, full_name, email, role, avatar_url, created_at'); // 👈 thêm avatar_url
    return (response as List)
        .map((row) => AppUser.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
