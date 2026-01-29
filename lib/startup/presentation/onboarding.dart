import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../config/colors.dart';
import '../../core/shared_components.dart';
import '../../features/auth/presentation/login.dart';
import 'footer.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController(initialPage: 0, keepPage: true);
  int currentPage = 0;

  final List<String> imagePaths = [
    'assets/images/spleash1.png',
    'assets/images/splea2.png',
    'assets/images/splea3.png',
    'assets/images/splea4.png',
    'assets/images/splea4.png',
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => currentPage == 0,
      child: Scaffold(
        body: Column(
          children: [
            // Header with "Skip" button aligned to the right
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentPage != imagePaths.length - 1)
                    OnboardingButton(
                      "Skip",
                          () {
                        setState(() {
                          currentPage = imagePaths.length - 1;
                        });
                        _pageController.jumpToPage(imagePaths.length - 1);
                      },
                    ),
                ],
              ),
            ),

            // Full screen image display
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: imagePaths.length,
                onPageChanged: (value) {
                  setState(() {
                    currentPage = value;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    imagePaths[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),

            // Footer with Next Button
            Footer(
              imagePaths.length,
              currentPage,
                  () {
                if (currentPage == imagePaths.length - 1) {
                  Navigator.of(context).pushReplacement(SharedComponents.routeOf(LoginScreen()));
                } else {
                  setState(() {
                    currentPage++;
                  });
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingButton extends StatelessWidget {
  final String data;
  final void Function() onClick;

  const OnboardingButton(this.data, this.onClick, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: SharedColors.primary,
        foregroundColor: SharedColors.buttonTextColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        data,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
      ),
    );
  }
}