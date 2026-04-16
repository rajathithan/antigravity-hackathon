import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock_data.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Hero: ${MockData.heroHeadline}',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 240),
                ExcludeSemantics(
                  child: Text(
                    MockData.heroHeadline,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Text(
                    MockData.heroSubtext,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 1,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 20),
                    Semantics(
                      hint: 'Use arrow keys or swipe to navigate the menu',
                      child: Text(
                        'SWIPE RIGHT TO SCROLL OR CLICK ON DISCOVER',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
