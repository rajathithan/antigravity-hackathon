import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock_data.dart';

class HorizontalParallaxItem extends StatelessWidget {
  final MenuItem item;
  final double relativePosition;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onGoHome;
  final bool isFirst;
  final bool isLast;

  const HorizontalParallaxItem({
    super.key,
    required this.item,
    required this.relativePosition,
    required this.onNext,
    required this.onPrevious,
    required this.onGoHome,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Frisbee effect: Spin and Scale from "back" to "front"
    final double scale = 1.0 - (relativePosition.abs() * 0.5).clamp(0.0, 0.5);
    final double rotation = relativePosition * 1.5;
    final double opacity = 1.0 - (relativePosition.abs() * 0.8).clamp(0.0, 1.0);

    // Accessible navigation label helpers
    final String prevLabel = isFirst ? 'Go back to home page' : 'View previous delicacy';
    final String nextLabel = isLast ? 'Go back to home page' : 'View next delicacy';

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image Column (The Frisbee)
                Expanded(
                  flex: 3,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translateByDouble(relativePosition * 200, 0, 0, 1)
                      ..scaleByDouble(scale, scale, 1, 1)
                      ..rotateZ(rotation),
                    child: Opacity(
                      opacity: opacity,
                      child: Semantics(
                        label: '${item.name} — ${item.description}',
                        image: true,
                        child: item.isNetworkImage
                            ? Image.network(
                                item.displayImage,
                                fit: BoxFit.contain,
                                semanticLabel: item.name,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(item.image, fit: BoxFit.contain),
                              )
                            : Image.asset(
                                item.image,
                                fit: BoxFit.contain,
                                semanticLabel: item.name,
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 80),

                // Content Column
                Expanded(
                  flex: 2,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(relativePosition * 150, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.toUpperCase(),
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.price,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Previous Delicacy OR Back to Home — Accessible
          if (relativePosition.abs() < 0.1)
            Positioned(
              bottom: 120,
              left: 80,
              child: Semantics(
                button: true,
                label: prevLabel,
                // Accessibility Optimization: Handle keyboard submission
                onTapHint: prevLabel,
                child: Tooltip(
                  message: prevLabel,
                  child: InkWell(
                    onTap: onPrevious,
                    mouseCursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            isFirst ? Icons.home_outlined : Icons.arrow_back,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isFirst ? 'BACK TO HOME' : 'PREVIOUS DELICACY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 3,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Next Delicacy OR Back to Home — Accessible
          if (relativePosition.abs() < 0.1)
            Positioned(
              bottom: 120,
              right: 80,
              child: Semantics(
                button: true,
                label: nextLabel,
                onTapHint: nextLabel,
                child: Tooltip(
                  message: nextLabel,
                  child: InkWell(
                    onTap: isLast ? onGoHome : onNext,
                    mouseCursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            isLast ? 'BACK TO HOME' : 'NEXT DELICACY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 3,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isLast ? Icons.first_page : Icons.arrow_forward,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
