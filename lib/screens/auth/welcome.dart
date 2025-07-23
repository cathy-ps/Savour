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
          // Logo
          Image.asset('assets/images/savour.png', height: 300),
          //const SizedBox(height: 24),
          const Text(
            "Welcome to Savour!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Savour your meals. Skip the waste.\n\nInstant recipes, organized recipes, smart shopping lists, and your own AI kitchen assistant!",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),

      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/recommended_recipe.png', height: 280),
          // const Icon(Icons.shopping_cart, size: 80, color: Color(0xFF00BF6D)),
          // const SizedBox(height: 24),
          const Text(
            "Instant Recipe Recommendations",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Just enter the ingredients you have and Savour will whip up recipes that match what’s in your kitchen. No more guessing, no more waste.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),

      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/cookbook.png', height: 280),
          const Text(
            "Your Personal Cookbook",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Save, organize, and revisit your favorite recipes anytime. Create collections, never lose a recipe you love, and find inspiration with ease.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/lists.png', height: 280),
          const Text(
            "Smart Shopping Made Easy",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Add recipe ingredients directly to your shopping list with a tap. Shop smarter, avoid duplicates, and keep your kitchen stocked for your next meal.",
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
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 560,
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
