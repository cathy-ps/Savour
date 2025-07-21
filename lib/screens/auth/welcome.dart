import 'package:flutter/material.dart';
import 'package:savourai/constant/colors.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'signin.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();
    final pages = [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            MediaQuery.of(context).platformBrightness == Brightness.light
                ? "https://i.postimg.cc/nz0YBQcH/Logo-light.png"
                : "https://i.postimg.cc/MHH0DKv1/Logo-dark.png",
            height: 120,
          ),
          const SizedBox(height: 24),
          const Text(
            "Welcome to SavourAI!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Discover, save, and cook delicious recipes with ease.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 80, color: Color(0xFF00BF6D)),
          const SizedBox(height: 24),
          const Text(
            "Smart Shopping Lists",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Easily add recipe ingredients to your shopping list.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 80, color: Color(0xFFFE9901)),
          const SizedBox(height: 24),
          const Text(
            "Your Personal Cookbook",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Organize your favorite recipes in one place.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 620,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: pages.length,
                      itemBuilder: (context, index) => pages[index],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Page indicator
                  StatefulBuilder(
                    builder: (context, setState) {
                      int currentPage = pageController.hasClients
                          ? pageController.page?.round() ?? 0
                          : 0;
                      pageController.addListener(() {
                        setState(() {});
                      });
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentPage == index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentPage == index
                                  ? AppColors.primary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignInScreen()),
                      );
                    },

                    size: ShadButtonSize.lg,
                    child: const Text("Get Started"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
