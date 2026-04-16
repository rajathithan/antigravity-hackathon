import 'package:flutter/material.dart';
import '../theme.dart';

class EateryAppBar extends StatelessWidget {
  const EateryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Premium Logo with Golden Glow — wrapped in RepaintBoundary for efficiency
          Stack(
            alignment: Alignment.center,
            children: [
              // Golden Aura
              Container(
                width: 500,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              // Large Logo
              RepaintBoundary(
                child: Semantics(
                  label: '4 to 8 Fine Dining logo',
                  image: true,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 320,
                    fit: BoxFit.contain,
                    semanticLabel: '4 to 8 Fine Dining',
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        '4 TO 8',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          letterSpacing: 8,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
