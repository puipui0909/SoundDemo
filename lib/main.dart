import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'service/audio_handler.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/theme.dart';
import 'theme/theme_notifier.dart';

import 'Screens/signin_screen.dart';
import 'Screens/register_screen.dart';
import 'Screens/main_page/home_screen.dart';
import 'package:spotify_clone/Screens/admin_page/admin_page.dart';
import 'package:spotify_clone/Screens/choose_theme_screen.dart';
import 'package:spotify_clone/Screens/get_started_screen.dart';
import 'package:spotify_clone/Screens/main_page/main_page.dart';


late final AudioPlayerHandler audioHandler;

void main() async {
  //connect to supabase
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://novatlcrmtyxyzepfdco.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vdmF0bGNybXR5eHl6ZXBmZGNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MTQ2OTgsImV4cCI6MjA3MzM5MDY5OH0.-pv_8ZSrmpkWsHHZtxC8Ftk5yX0iUd2DceeuJ21IsC4',
  );

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.spotify_clone.channel.playback',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const MyApp()
      ),
  );
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
        initialRoute: '/getstarted',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/signin': (context) => const SignInScreen(),
          '/register': (context) => const RegisterScreen(),
          '/getstarted': (context) => const GetStartedScreen(),
          '/theme': (context) => const chooseThemeScreen(),
          '/main': (context) => const MainPage(),
          '/admin': (context) => const AdminPage(),
        },
        debugShowCheckedModeBanner: false,
      title: 'Spotify',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
    );
  }

}
