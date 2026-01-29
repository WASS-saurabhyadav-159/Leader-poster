import 'package:flutter/material.dart';


class SharedComponents {
  static Widget scaffolded(Widget child) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(child: child),
      ),
    );
  }
  
  static MaterialPageRoute routeOf(Widget page) {
    return MaterialPageRoute(builder: (_) => scaffolded(page));
  }
}