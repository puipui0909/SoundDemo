import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:spotify_clone/Screens/main_page/profile_screen.dart';
import 'package:spotify_clone/main.dart';
import 'package:spotify_clone/widgets/now_playing_bar.dart';

import 'home_screen.dart';
import 'library.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }


  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      LibraryScreen(),
      ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.library_music),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        activeColorPrimary: Theme.of(context).colorScheme.primary,
        inactiveColorPrimary: Theme.of(context).unselectedWidgetColor,
      ),
    ];
  }
  static const double bottomNavBarHeight = 60.0;
  static const double miniPlayerHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          final bool isMusicPlaying = mediaItem != null;

          return Stack(
              children: [

                // 1. PersistentTabView (Nội dung chính)
                // Bỏ Expanded. PersistentTabView sẽ tự động chiếm toàn bộ Stack.
                PersistentTabView(
                  context,
                  controller: _controller,
                  screens: _buildScreens(),
                  items: _navBarsItems(),
                  navBarStyle: NavBarStyle.style6,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),

                // 2. MINI-PLAYER (Điều kiện) - Giữ nguyên
                if (isMusicPlaying)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NowPlayingBar(),
                        // Đệm: Đảm bảo Mini-Player nằm ngay trên Nav Bar
                        SizedBox(height: bottomNavBarHeight),
                      ],
                    ),
                  ),
              ]
          );
        }
    );
  }
}