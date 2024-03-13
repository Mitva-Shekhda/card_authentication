import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'implement_card_details.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  MyHomePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
          automaticallyImplyLeading: false
      ),
      body: AddCardScreen()
    );
  }
}
