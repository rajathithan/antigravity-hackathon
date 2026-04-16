import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock_data.dart';

class ScrollProgressIndicator extends StatelessWidget {
  final double currentPage;
  final int totalItems;

  const ScrollProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = ((currentPage + 1) / totalItems).clamp(0.0, 1.0);
    return Semantics(
      label: 'Menu progress',
      value: '${(currentPage + 1).round()} of $totalItems', // Accessibility improvement
      slider: true,
      child: SizedBox(
        width: 300,
        height: 4,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScrollHintIndicator extends StatefulWidget {
  final VoidCallback onTap;
  const ScrollHintIndicator({super.key, required this.onTap});

  @override
  State<ScrollHintIndicator> createState() => _ScrollHintIndicatorState();
}

class _ScrollHintIndicatorState extends State<ScrollHintIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Animation is started in didChangeDependencies to respect reduced-motion preference.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Discover the menu — tap to navigate to the first delicacy',
      child: Tooltip(
        message: 'Tap to explore the menu',
        child: InkWell(
          onTap: widget.onTap,
          mouseCursor: SystemMouseCursors.click,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(10 * _controller.value, 0),
                child: Row(
                  children: [
                    Text(
                      'DISCOVER',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class TimeStatusIndicator extends StatelessWidget {
  const TimeStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isOpen = MockData.isShopOpen();
    return Semantics(
      label: isOpen ? 'Status: Experience is open now' : 'Status: Reservations open at 3 PM',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isOpen ? Colors.green : Colors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon for color-blind accessibility
            Icon(
              isOpen ? Icons.circle : Icons.schedule,
              color: isOpen ? Colors.green : Colors.white54,
              size: 8,
            ),
            const SizedBox(width: 8),
            Text(
              MockData.getTimeStatus(),
              style: TextStyle(
                color: isOpen ? Colors.green : Colors.white54,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
