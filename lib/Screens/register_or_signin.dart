import 'package:flutter/material.dart';

class RegisterOrSign extends StatelessWidget{
  const RegisterOrSign({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
            padding: EdgeInsets.all(8.0),
            child: IconButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back),),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 45,
                  bottom:30),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,// màu mặc định
                  ),
                  children: [
                    const TextSpan(
                      text: 'Sound',
                      style: TextStyle(color: Colors.green),
                    ),
                    const TextSpan(
                      text: 'Demo',
                    ),
                  ],
                ),
              )
            ),
            Text('Enjoy listening to music', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
            SizedBox(height: 25,),
            Container(
              width: 306,
              height: 46,
              child: Text('Spotify is a proprietary Swedish audio streaming and media services provider',
                style: TextStyle(fontSize: 17), textAlign: TextAlign.center, ),
            ),
            SizedBox(height: 25,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: Size(147, 73),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (){
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text('Register', style: TextStyle(fontSize: 19),)),
                SizedBox(width: 30,),
                TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: Size(147, 73)
                    ),
                    onPressed: (){
                      Navigator.pushNamed(context, '/signin');
                    },
                    child: Text('Sign in', style: TextStyle(fontSize: 19),))
              ],
            )
          ],
        ),
      ),
    );
  }

}