import 'package:flutter/material.dart';

class GetStartedScreen extends StatelessWidget{
  const GetStartedScreen ({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Welcome', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),)
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    children: [
                      Text('Enjoy Listening To Music',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white)),
                      SizedBox(height: 10,),
                      Container(
                        width: 297,
                        height: 92,
                        child: Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sagittis enim purus sed phasellus. Cursus ornare id scelerisque aliquam.',
                          style:  TextStyle(color: Colors.grey, fontSize: 17), textAlign: TextAlign.center,),
                      ),
                      SizedBox(height: 20,),
                      TextButton(
                          onPressed: (){
                            Navigator.pushNamed(context, '/theme');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(329, 92),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)
                            )
                          ),
                          child: Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),))
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