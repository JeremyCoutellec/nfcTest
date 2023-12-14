import 'package:flutter/material.dart';
import 'package:flutter_nfc/src/nfc_feature/nfc_read_view.dart';
import 'package:flutter_nfc/src/nfc_feature/nfc_write_view.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';

import 'core/nav_bar_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _tabController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: NavBar(context: context),
        bottomNavigationBar: MotionTabBar(
          initialSelectedTab: "Lecture",
          labels: const ["Lecture", "Ecriture"],
          icons: const [
            Icons.nfc_rounded,
            Icons.edit_rounded,
          ],
          tabSize: 50,
          tabBarHeight: 55,
          textStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
          tabIconColor: Theme.of(context).primaryColor,
          tabIconSize: 28.0,
          tabIconSelectedSize: 26.0,
          tabSelectedColor: Theme.of(context).primaryColor,
          tabIconSelectedColor: Colors.white,
          tabBarColor: Colors.white,
          onTabItemSelected: (int value) {
            setState(() {
              _tabController!.index = value;
            });
          },
        ),
        body: TabBarView(
          physics:
              const NeverScrollableScrollPhysics(), // swipe navigation handling is not supported
          controller: _tabController,
          // ignore: prefer_const_literals_to_create_immutables
          children: const <Widget>[
            NfcReadView(),
            NfcWriteView(),
          ],
        ));
  }
}
