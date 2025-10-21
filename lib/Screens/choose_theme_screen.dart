import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify_clone/Screens/register_or_signin.dart';
import 'package:spotify_clone/theme/theme_notifier.dart';

class chooseThemeScreen extends StatelessWidget{
  const chooseThemeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final curentMode = themeNotifier.themeMode;
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('SoundDemo', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                  Container(
                    height: 177,
                    width: 233,
                    child: Column(
                      children: [
                        Text('Choose Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.light_mode),
                                    onPressed: (){
                                      themeNotifier.setTheme(ThemeMode.light);
                                    },
                                    iconSize: 50,
                                ),
                                Text('Light Mode',style: TextStyle(fontSize: 13),)
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.dark_mode),
                                    onPressed: (){
                                      themeNotifier.setTheme(ThemeMode.dark);
                                    },
                                    iconSize: 50,
                                ),
                                Text('Dark Mode', style: TextStyle(fontSize: 13),)
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),

                  SizedBox(height: 50,),
                  TextButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterOrSign()));
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(329, 92),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)
                      )
                    ),
                  child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),))
                ],
                ),
    )
    ],
    )
    ),
    )
    );
    }

}
