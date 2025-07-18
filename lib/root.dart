import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'constant/AppColor.dart';
import 'screens/home_screen.dart';
import 'screens/cookbook.dart';
import 'screens/shoppinglist.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  int _selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [HomeScreen(), CookbookScreen(), ShoppingListScreen()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: GNav(
            rippleColor: AppColor.secondary.withOpacity(0.2),
            hoverColor: AppColor.secondary.withOpacity(0.1),
            haptic: true,
            tabBorderRadius: 18,
            tabActiveBorder: Border.all(color: AppColor.primary, width: 1),
            tabBorder: Border.all(color: AppColor.darkGrey, width: 1),
            tabShadow: [
              BoxShadow(color: AppColor.muted.withOpacity(0.2), blurRadius: 8),
            ],
            curve: Curves.easeOutExpo,
            duration: Duration(milliseconds: 500),
            gap: 8,
            color: AppColor.darkGrey,
            activeColor: AppColor.primary,
            iconSize: 24,
            tabBackgroundColor: AppColor.primary.withOpacity(0.1),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            tabs: [
              GButton(
                icon: Icons.home_outlined,
                text: 'Home',
                textStyle: optionStyle,
              ),
              GButton(
                icon: Icons.book_outlined,
                text: 'Cookbook',
                textStyle: optionStyle,
              ),
              GButton(
                icon: Icons.shopping_cart_outlined,
                text: 'Shop',
                textStyle: optionStyle,
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
