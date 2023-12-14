import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NavBar extends AppBar {
  PreferredSizeWidget? bottomNavbar;
  String? titleNavBar;

  NavBar(
      {super.key,
      required BuildContext context,
      this.bottomNavbar,
      this.titleNavBar})
      : super(
            title: Row(children: [
              Text(titleNavBar ?? 'NFC Test',
                  style: const TextStyle(
                    color: Colors.white,
                  ))
            ]),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            bottom: bottomNavbar,
            actions: []);
}
