import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:savourai/constant/colors.dart';
import 'package:savourai/screens/home.dart';
import '../screens/cookbook.dart';
import '../screens/shoppinglist.dart';
import 'package:flutter/cupertino.dart';

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    CookbookScreen(),
    ShoppingListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('SavourAI')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: const Icon(CupertinoIcons.home),
            title: const Text("Home"),
            selectedColor: AppColors.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(CupertinoIcons.folder),
            title: const Text("Cookbook"),
            selectedColor: AppColors.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(CupertinoIcons.list_bullet_below_rectangle),
            title: const Text("Shopping List"),
            selectedColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
