import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'data/mock_data.dart';
import 'data/menu_service.dart';
import 'admin/admin_page.dart';

import 'widgets/eatery_app_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/horizontal_parallax_item.dart';
import 'widgets/indicators.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4 to 8 | Fine Dining',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: AppTheme.eateryTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HorizontalEateryPage(),
        '/admin': (_) => const AdminLoginPage(),
      },
    );
  }
}

class HorizontalEateryPage extends StatefulWidget {
  const HorizontalEateryPage({super.key});

  @override
  State<HorizontalEateryPage> createState() => _HorizontalEateryPageState();
}

class _HorizontalEateryPageState extends State<HorizontalEateryPage> {
  late PageController _pageController;
  final MenuService _menuService = MenuService();
  late Future<List<MenuItem>> _menuFuture;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _menuFuture = _menuService.fetchMenuItems();
    _pageController = PageController(viewportFraction: 1.0);
    // REMOVED _pageController.addListener(...) with setState
    // This is the primary efficiency improvement.
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_pageController.hasClients) {
      // PageView naturally clamps at the last page; no manual guard needed,
      // and a stale guard (e.g. MockData length) would block API-served pages.
      _pageController.nextPage(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _navigateToHome() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _navigateToPrevious() {
    if (_pageController.hasClients) {
       if ((_pageController.page ?? 0.0) > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    }
  }
  
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _navigateToNext();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _navigateToPrevious();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<List<MenuItem>>(
          future: _menuFuture,
          builder: (context, snapshot) {
            final items = snapshot.hasData && snapshot.data!.isNotEmpty
                ? snapshot.data!
                : MockData.dailyItems;

            return Stack(
              children: [
                // Main Horizontal PageView
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length + 1, // +1 for Hero Section
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const HeroSection();
                    }
                    final itemIndex = index - 1;
                    final item = items[itemIndex];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double pageOffset = 0;
                        if (_pageController.position.haveDimensions) {
                          pageOffset = _pageController.page ?? 0.0;
                        }
                        return HorizontalParallaxItem(
                          item: item,
                          relativePosition: index - pageOffset,
                          onNext: _navigateToNext,
                          onPrevious: _navigateToPrevious,
                          onGoHome: _navigateToHome,
                          isFirst: index == 1,
                          isLast: index == items.length,
                        );
                      },
                    );
                  },
                ),

                // Logo (Center Top) - Fades out
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (_pageController.position.haveDimensions) {
                        pageOffset = _pageController.page ?? 0.0;
                      }
                      return Opacity(
                        opacity: (1.0 - pageOffset).clamp(0.0, 1.0),
                        child: const EateryAppBar(),
                      );
                    },
                  ),
                ),

                // Time Status Badge (Top Right) - Fades out
                Positioned(
                  top: 40,
                  right: 40,
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (_pageController.position.haveDimensions) {
                        pageOffset = _pageController.page ?? 0.0;
                      }
                      return Opacity(
                        opacity: (1.0 - pageOffset).clamp(0.0, 1.0),
                        child: const TimeStatusIndicator(),
                      );
                    },
                  ),
                ),

                // Horizontal Progress Indicator (Bottom)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double pageOffset = 0;
                        if (_pageController.position.haveDimensions) {
                          pageOffset = _pageController.page ?? 0.0;
                        }
                        return ScrollProgressIndicator(
                          currentPage: pageOffset,
                          totalItems: items.length + 1,
                        );
                      },
                    ),
                  ),
                ),

                // "Scroll to Explore" Affordance (Only on Hero)
                Positioned(
                  bottom: 120,
                  right: 80,
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0;
                      if (_pageController.position.haveDimensions) {
                        pageOffset = _pageController.page ?? 0.0;
                      }
                      if (pageOffset < 0.5) {
                        return ScrollHintIndicator(
                          onTap: _navigateToNext,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
